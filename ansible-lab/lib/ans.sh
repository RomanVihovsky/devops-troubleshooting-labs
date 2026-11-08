# shellcheck shell=bash
# Controller / node / git / verify helpers. Sourced after lib/common.sh.
#
# Conventions for scenario scripts (.lab/setup.sh, verify.sh, solve.sh) - they run on the HOST:
#   $WS              the student's repo (workspace/), mounted in the controller at /work
#   $CI              fresh "CI checkout" of the workspace (verify only), mounted at /ci
#   $SCN             the scenario's own directory
#   ap <args>        ansible-playbook in /work, as the team ran it (setup/solve)
#   ctl <cmd>        any shell command in the controller, in /work (setup/solve) - ctl_ci for /ci
#   nx <node> <cmd>  root shell command on a managed node
#   nodes: declared in scenario.yaml; fresh containers per lab, host keys trusted by ./lab

CI="$STATE_DIR/ci"
SETUP_LOG="$STATE_DIR/setup.log"
VERIFY_LOG="$STATE_DIR/verify.log"
SSH_DIR="$STATE_DIR/ssh"
GIT_DIR_LAB="$STATE_DIR/git"
REGISTRY_URL="https://git.acme.example"     # fake corporate git host -> .state/git (url.insteadOf)

# ------------------------------------------------------------ the fleet -----
# shellcheck disable=SC2034
ALL_NODES="lb1 web1 web2 web3 app1 app2 db1 test1"   # debian: lb1 web1 web3 app1 test1 · rocky: web2 app2 db1
node_os() {
  case $1 in
    lb1|web1|web3|app1|test1) echo debian ;;
    web2|app2|db1) echo rocky ;;
    *) return 1 ;;
  esac
}
node_ip() {
  case $1 in
    lb1) echo 10.78.0.10 ;; web1) echo 10.78.0.11 ;; web2) echo 10.78.0.12 ;; web3) echo 10.78.0.13 ;;
    app1) echo 10.78.0.14 ;; app2) echo 10.78.0.15 ;; db1) echo 10.78.0.21 ;; test1) echo 10.78.0.31 ;;
    *) return 1 ;;
  esac
}
node_image() { if [ "$(node_os "$1")" = rocky ]; then echo "$NODE_ROCKY_IMAGE"; else echo "$NODE_DEBIAN_IMAGE"; fi; }
running() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = true ]; }

# lab_env: nothing to export on the host (all tools live in the controller); per-lab env (lab_setenv) is
# passed into the controller by ctl/ap.
lab_env() { :; }
lab_setenv() { printf '%s=%q\n' "$1" "$2" >> "$STATE_DIR/scenario.env"; export "$1=$2"; }
ctl_env_args() {
  local k v
  [ -f "$STATE_DIR/scenario.env" ] || return 0
  while IFS='=' read -r k v; do [ -n "$k" ] && printf -- '-e\n%s=%s\n' "$k" "$(eval "printf %s $v")"; done < "$STATE_DIR/scenario.env"
}

# ---------------------------------------------------------- infrastructure ---
write_configs() {
  mkdir -p "$SSH_DIR" "$GIT_DIR_LAB" "$WS" "$CI" "$CACHE_DIR/collections" "$CACHE_DIR/wheels" "$CACHE_DIR/pypi"
  chmod 700 "$SSH_DIR"
  [ -f "$SSH_DIR/id_ed25519" ] || ssh-keygen -q -t ed25519 -N '' -C ansible-lab -f "$SSH_DIR/id_ed25519"
  printf 'Host *\n  IdentityFile ~/.ssh/id_ed25519\n  UserKnownHostsFile ~/.ssh/known_hosts\n  ConnectTimeout 10\n' > "$SSH_DIR/config"
  chmod 600 "$SSH_DIR/config"
  touch "$SSH_DIR/known_hosts"
  cat > "$STATE_DIR/gitconfig" <<EOF
[user]
	name = You
	email = you@acme.example
[init]
	defaultBranch = main
[advice]
	detachedHead = false
[safe]
	directory = *
[protocol "file"]
	allow = always
[url "file:///srv/git/"]
	insteadOf = $REGISTRY_URL/
EOF
}
net_up() {
  docker network inspect "$NET" >/dev/null 2>&1 ||
    docker network create --internal --subnet 10.78.0.0/24 --label ansiblelab.infra=net "$NET" >/dev/null
}
repo_up() {
  running ans-repo && return 0
  docker rm -f ans-repo >/dev/null 2>&1 || true
  docker run -d --name ans-repo --network "$NET" --ip 10.78.0.2 --network-alias repo.acme.internal \
    --label ansiblelab.infra=repo --memory 64m \
    -v "$CACHE_DIR/mirror:/srv/mirror:ro" -v "$LAB_DIR/infra/repo/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
    "$REPO_IMAGE" >/dev/null
}
ctl_up() {
  # recreate when the image changed (wave 2 moved the controller from ctl:1 to ctl:2)
  running "$CTL" && [ "$(docker inspect -f '{{.Config.Image}}' "$CTL" 2>/dev/null)" = "$CTL_IMAGE" ] && return 0
  docker rm -f "$CTL" >/dev/null 2>&1 || true
  docker run -d --name "$CTL" --hostname ctl --network "$NET" --ip 10.78.0.5 --network-alias ctl \
    --label ansiblelab.infra=ctl --memory 1g --cpus 2 \
    -v "$WS:/work" -v "$CI:/ci" -v "$SSH_DIR:/home/ops/.ssh" -v "$GIT_DIR_LAB:/srv/git" \
    -v "$STATE_DIR/gitconfig:/home/ops/.gitconfig:ro" \
    -v "$CACHE_DIR/collections:/opt/collections:ro" -v "$CACHE_DIR/wheels:/opt/wheels:ro" \
    -v "$CACHE_DIR/pypi:/opt/pypi:ro" \
    "$CTL_IMAGE" >/dev/null
}
infra_up() { write_configs; net_up; repo_up; ctl_up; }

# ------------------------------------------------------------------ nodes ---
node_up() {   # node_up <name> [image]
  local n=$1 img=${2:-$(node_image "$1")}
  docker rm -f "ans-$n" >/dev/null 2>&1 || true
  docker run -d --name "ans-$n" --hostname "$n" --network "$NET" --ip "$(node_ip "$n")" \
    --network-alias "$n" --network-alias "$n.acme.internal" \
    --cgroupns=private --tmpfs /run --tmpfs /run/lock --cap-add SYS_ADMIN \
    --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
    --memory 384m --cpus 1 --label "ansiblelab.scenario=${LAB_ID:-lab}" "$img" >/dev/null
}
node_booted() {
  case "$(docker exec "ans-$1" systemctl is-system-running 2>/dev/null)" in running|degraded) return 0 ;; esac
  return 1
}
node_key() {
  docker exec -i "ans-$1" sh -c 'install -d -m 700 -o ansible -g ansible /home/ansible/.ssh &&
    cat > /home/ansible/.ssh/authorized_keys && chown ansible:ansible /home/ansible/.ssh/authorized_keys &&
    chmod 600 /home/ansible/.ssh/authorized_keys' < "$SSH_DIR/id_ed25519.pub"
}
# trust_hosts <node...>: (re)write known_hosts entries for name, name.acme.internal and IP
trust_hosts() {
  local n names=()
  for n in "$@"; do names+=("$n" "$n.acme.internal" "$(node_ip "$n")"); done
  for n in "${names[@]}"; do ssh-keygen -q -R "$n" -f "$SSH_DIR/known_hosts" >/dev/null 2>&1 || true; done
  # shellcheck disable=SC2016
  retry 20 docker exec -u ops "$CTL" sh -c 'ssh-keyscan -q -t ed25519 "$@" >> ~/.ssh/known_hosts 2>/dev/null &&
    for h in "$@"; do grep -q "^$h " ~/.ssh/known_hosts || exit 1; done' _ "${names[@]}"
  rm -f "$SSH_DIR/known_hosts.old"
}
# nodes_up <node...>: fresh nodes, booted, key installed, host keys trusted
nodes_up() {
  local n
  [ $# -gt 0 ] || return 0
  for n in "$@"; do node_up "$n"; done
  for n in "$@"; do retry 60 node_booted "$n" || die "node $n did not boot (docker logs ans-$n)"; done
  for n in "$@"; do node_key "$n"; done
  for n in "$@"; do retry 20 docker exec "ans-$n" sh -c 'systemctl is-active ssh >/dev/null 2>&1 || systemctl is-active sshd >/dev/null 2>&1'; done
  for n in "$@"; do first_boot "$n"; done
  trust_hosts "$@"
}
# first_boot <n>: what cloud-init does on a real image - refresh the package index from the mirror
first_boot() {
  if [ "$(node_os "$1")" = debian ]; then
    retry 20 docker exec "ans-$1" apt-get update -qq || die "apt-get update on $1 failed (mirror up?)"
  else
    retry 20 docker exec "ans-$1" dnf -q makecache || die "dnf makecache on $1 failed (mirror up?)"
  fi
}
# node_rebuild <n>: what the "golden image" pipeline does - fresh container, key installed, NOT re-trusted
node_rebuild() {
  node_up "$1"
  retry 60 node_booted "$1" || die "node $1 did not boot"
  node_key "$1"
  retry 20 docker exec "ans-$1" sh -c 'systemctl is-active ssh >/dev/null 2>&1 || systemctl is-active sshd >/dev/null 2>&1'
  first_boot "$1"
}
nodes_down() {
  { docker ps -a --filter label=ansiblelab.scenario --format '{{.Names}}'
    docker ps -a --format '{{.Names}}' | grep -E '^ans-(lb|web|app|db|test)[0-9]' || true
  } | sort -u | grep . | xargs -r docker rm -f >/dev/null 2>&1 || true
  docker volume ls -q --filter label=ansiblelab.scenario | xargs -r docker volume rm >/dev/null 2>&1 || true
}
nx()  { local n=$1; shift; docker exec "ans-$n" bash -c "$*"; }        # root on a node
nxi() { docker exec -i "ans-$1" bash -s; }                             # script from stdin
svc_active() { nx "$1" "systemctl is-active --quiet $2"; }
remember_node() { remember "node.$1" "$(docker inspect -f '{{.Id}}' "ans-$1")"; }
same_node()     { [ "$(docker inspect -f '{{.Id}}' "ans-$1" 2>/dev/null)" = "$(recall "node.$1")" ]; }

# ------------------------------------------------------------- controller ---
# ctl <cmd...> : shell command as "ops" in /work (setup/solve act like the team)
ctl() {
  local args=()
  mapfile -t args < <(ctl_env_args)
  docker exec -u ops -w /work -e ANSIBLE_NOCOLOR=1 -e ANSIBLE_FORCE_COLOR=0 "${args[@]}" "$CTL" bash -c "$*"
}
ctl_ci() {
  local args=()
  mapfile -t args < <(ctl_env_args)
  docker exec -u ops -w /ci -e ANSIBLE_NOCOLOR=1 -e ANSIBLE_FORCE_COLOR=0 "${args[@]}" "$CTL" bash -c "$*"
}
ap() { run_logged "$SETUP_LOG" ctl "ansible-playbook $*"; }

# --------------------------------------------------------------- workspace ---
# The workspace and CI dirs are bind-mounted into the controller: empty them, never delete them.
empty_dir() { mkdir -p "$1"; find "$1" -mindepth 1 -maxdepth 1 -exec rm -rf {} +; }
ws_reset() { empty_dir "$WS"; empty_dir "$CI"; git -C "$WS" init -q -b main; }
ws_commit() {
  local who=${2:-"Platform Team"}
  git -C "$WS" add -A
  git -C "$WS" -c user.name="$who" -c user.email="platform@acme.example" commit -q --allow-empty -m "$1"
}
untouched() {
  git -C "$WS" diff --quiet "$(recall asfound)" -- "$@" &&
    [ -z "$(git -C "$WS" ls-files --others --exclude-standard -- "$@")" ]
}
# ws_has <ERE>: pattern appears in the repo's Ansible content
ws_has() {
  grep -rqsE --include='*.yml' --include='*.yaml' --include='*.cfg' --include='*.j2' --include='*.sh' \
    --include='*.ini' --exclude-dir=.git --exclude-dir=.ansible -e "$1" "$WS"
}
# shellcheck disable=SC2016
vault_encrypted() { head -1 "$1" 2>/dev/null | grep -q '^\$ANSIBLE_VAULT;1\.[12];AES256'; }

# publish <repo> <tag|-> <src_dir> [message]: next version of $REGISTRY_URL/platform/<repo>.git
publish() {
  local repo=$1 tag=$2 src=$3 msg=${4:-"release $2"} bare tmp
  bare="$GIT_DIR_LAB/platform/$repo.git"
  [ -d "$bare" ] || { mkdir -p "$(dirname "$bare")"; git init -q --bare -b main "$bare"; }
  tmp=$(mktemp -d)
  git clone -q "$bare" "$tmp/r" 2>/dev/null
  find "$tmp/r" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp -a "$src"/. "$tmp/r"/
  git -C "$tmp/r" add -A
  git -C "$tmp/r" -c user.name="Platform Team" -c user.email="platform@acme.example" commit -q --allow-empty -m "$msg"
  [ "$tag" = - ] || git -C "$tmp/r" tag "$tag"
  git -C "$tmp/r" push -q origin main --tags
  rm -rf "$tmp"
}

# run_lab_script <script> <dir> [bash flags]: a NEW bash process with the libs loaded (bash ignores
# `set -e` inside `if`/`||` contexts - a failing setup would otherwise be swallowed).
run_lab_script() {
  local script=$1 dir=$2 flags=${3:--euo pipefail}
  # shellcheck disable=SC2016,SC2086
  SCN="$(dirname "$(dirname "$script")")" LAB_DIR="$LAB_DIR" LAB_ID="${LAB_ID:-}" bash $flags -c '
    source "$LAB_DIR/lib/common.sh"; source "$LAB_DIR/lib/ans.sh"; lab_env
    if [ -f "$STATE_DIR/scenario.env" ]; then set -a; source "$STATE_DIR/scenario.env"; set +a; fi
    cd "$2" && source "$1"' _ "$script" "$dir"
}
run_logged() {
  local log=$1; shift
  echo "+ $*" >> "$log"
  if ! "$@" >> "$log" 2>&1; then
    echo "${C_R}command failed:${C_0} $*" >&2
    tail -25 "$log" | sed 's/^/    /' >&2
    return 1
  fi
}

# ------------------------------------------------- verify: CI checkout -----
ci_checkout() {
  empty_dir "$CI"
  tar -C "$WS" --exclude=./.ansible -cf - . | tar -C "$CI" -xf -
  : > "$VERIFY_LOG"
}
# ap_json <args...>: ansible-playbook in /ci with the JSON callback; stats -> $CI/.lab-ap.json
ap_json() { ci_json ansible-playbook "$@"; }
# ci_json <cmd...>: any command in /ci that runs ansible-playbook (a CI job script like ci/deploy.sh) with the
# JSON callback; the playbook's JSON document -> $CI/.lab-ap.json (one playbook per command)
ci_json() {
  local args=() rc=0
  mapfile -t args < <(ctl_env_args)
  echo "+ $*" >> "$VERIFY_LOG"
  docker exec -u ops -w /ci -e ANSIBLE_STDOUT_CALLBACK=ansible.posix.json -e ANSIBLE_NOCOLOR=1 "${args[@]}" \
    "$CTL" "$@" > "$CI/.lab-ap.raw" 2>> "$VERIFY_LOG" || rc=$?
  # the repo's own callbacks (profile_tasks, timer...) print around the JSON document - cut it out
  # (an empty ANSIBLE_CALLBACKS_ENABLED crashes 2.22: "A non-empty plugin name is required")
  sed -n '/^{$/,/^}$/p' "$CI/.lab-ap.raw" > "$CI/.lab-ap.json"
  grep -v -e '^{$' -e '^}$' "$CI/.lab-ap.raw" | sed -n '/^[A-Za-z=]/p' | head -5 >> "$VERIFY_LOG" || true
  jq -c '.stats // "no stats"' "$CI/.lab-ap.json" >> "$VERIFY_LOG" 2>&1 || cat "$CI/.lab-ap.json" >> "$VERIFY_LOG"
  return $rc
}
stats_ok() {   # stats_ok <jq condition on each host's stats>
  jq -e --arg c "$1" '(.stats | length) > 0' "$CI/.lab-ap.json" >/dev/null 2>&1 &&
    jq -e "[.stats[] | ($1)] | all" "$CI/.lab-ap.json" >/dev/null 2>&1
}
# converged <playbook> [args]: check mode -> no changes, no failures, every host reachable
converged() { ap_json "$@" --check && stats_ok '.changed == 0 and .failures == 0 and .unreachable == 0'; }
# applies <playbook> [args]: a real run without failures
applies() { ap_json "$@" && stats_ok '.failures == 0 and .unreachable == 0'; }
# idempotent <playbook> [args]: a real run, then a second one that changes nothing
idempotent() { applies "$@" && ap_json "$@" && stats_ok '.changed == 0 and .failures == 0 and .unreachable == 0'; }
# out_has / out_lacks <string>: in the last ap_json run's full JSON output (task results, msgs)
out_has()   { grep -qF -- "$1" "$CI/.lab-ap.json"; }
http_get()  { docker exec "$CTL" curl -fsS --max-time 5 "$1"; }
lint_ok()   { ctl_ci "ansible-lint ${1:-}" >> "$VERIFY_LOG" 2>&1; }
# task_result <task name>: per-host results of that task in the last ap_json run (JSON lines)
task_result() {   # matches "name" and role-prefixed "role : name"
  jq -c --arg n "$1" '.plays[].tasks[] | select(.task.name == $n or (.task.name | endswith(" : " + $n))) | .hosts' \
    "$CI/.lab-ap.json" 2>/dev/null
}
task_skipped()     { [ -n "$(task_result "$1")" ] && task_result "$1" | jq -e '[.[] | .skipped == true] | all' >/dev/null; }
task_not_skipped() { [ -n "$(task_result "$1")" ] && task_result "$1" | jq -e '[.[] | (.skipped // false) == false] | all' >/dev/null; }
# no_broken_conditionals_escape: the 2.19+ safety net may not be switched off
no_broken_cond_escape() { ! ws_has '(allow_broken_conditionals|ALLOW_BROKEN_CONDITIONALS)'; }

# ------------------------------------------------- wave 2: EDA activation ---
# ans-eda = the EDA "activation": ansible-rulebook from a project checkout (/work or /ci), started per lab.
# Monitoring posts alerts to $EDA_URL; the rulebook's run_playbook actions run against the lab nodes.
EDA=ans-eda
EDA_URL=http://eda.acme.internal:5000/endpoint
eda_conf() {   # eda_conf <project> <rulebook> [inventory]
  mkdir -p "$STATE_DIR/eda"
  printf 'PROJECT=%s\nRULEBOOK=%s\nINVENTORY=%s\n' "$1" "$2" "${3:-inventory/hosts.yml}" > "$STATE_DIR/eda/activation.env"
}
eda_listening() { docker exec "$CTL" curl -s -o /dev/null --max-time 2 "http://eda.acme.internal:5000/"; }
# eda_up <rulebook> [inventory]: start the activation on the workspace (/work)
eda_up() {
  eda_conf /work "$1" "${2:-}"
  docker rm -f "$EDA" >/dev/null 2>&1 || true
  docker run -d --name "$EDA" --hostname eda --network "$NET" --ip 10.78.0.7 \
    --network-alias eda --network-alias eda.acme.internal \
    --label "ansiblelab.scenario=${LAB_ID:-lab}" --memory 768m --cpus 1 \
    -v "$WS:/work" -v "$CI:/ci" -v "$SSH_DIR:/home/ops/.ssh" -v "$STATE_DIR/eda:/srv/eda:ro" \
    -v "$LAB_DIR/infra/eda/activation.sh:/opt/eda/activation.sh:ro" \
    -w /work "$CTL_IMAGE" bash /opt/eda/activation.sh >/dev/null
  retry 60 eda_listening || { docker logs --tail 30 "$EDA" >&2; die "EDA activation did not start"; }
}
# eda_restart [project]: re-read the project (like syncing the project + restarting the activation)
eda_restart() {
  local p=${1:-/work} rb inv
  rb=$(sed -n 's/^RULEBOOK=//p' "$STATE_DIR/eda/activation.env"); inv=$(sed -n 's/^INVENTORY=//p' "$STATE_DIR/eda/activation.env")
  eda_conf "$p" "$rb" "$inv"
  docker restart -t 2 "$EDA" >/dev/null
  retry "${EDA_WAIT:-45}" eda_listening
}
# eda_post <json>: what the monitoring does - POST an alert to the webhook (from the controller)
eda_post() {
  docker exec "$CTL" curl -fsS --max-time 5 -H 'Content-Type: application/json' -d "$1" "$EDA_URL" >/dev/null
}
eda_log() { docker logs "$EDA" 2>&1; }

# ------------------------------------------------------ wave 2: fake AWS ---
# ans-aws = moto (EC2 API) at http://aws.acme.internal:4566. Instances are created with the PrivateIpAddress of
# real lab nodes, so the EC2 inventory resolves to machines you can SSH to. The credentials/endpoint live in
# the runner's environment (lab_setenv), as on a real CI runner - not in the repo.
AWS=ans-aws
aws_up() {
  docker rm -f "$AWS" >/dev/null 2>&1 || true
  docker run -d --name "$AWS" --hostname aws --network "$NET" --ip 10.78.0.6 \
    --network-alias aws.acme.internal --label "ansiblelab.scenario=${LAB_ID:-lab}" --memory 384m --cpus 1 \
    "$MOTO_IMAGE" >/dev/null
  retry 60 docker exec "$CTL" curl -fsS -o /dev/null --max-time 2 http://aws.acme.internal:4566/moto-api/ ||
    die "fake AWS (moto) did not start"
  lab_setenv AWS_ENDPOINT_URL http://aws.acme.internal:4566
  lab_setenv AWS_ACCESS_KEY_ID acme-ci-runner-dummy-key   # moto accepts anything; not shaped like a real key ID
  lab_setenv AWS_SECRET_ACCESS_KEY acme-ci-runner-dummy-secret
  lab_setenv AWS_DEFAULT_REGION eu-west-1
}
# aws <cmd> [args]: the cloud team's API (lib/aws_fleet.py) - launch/stop/terminate instances, list
#   aws launch <name> <node-or-ip> <role> [env=prod] [region=eu-west-1]   aws stop|terminate <name> [region]
aws() {
  local args=()
  mapfile -t args < <(ctl_env_args)
  docker exec -i -u ops "${args[@]}" "$CTL" python3 - "$@" < "$LAB_DIR/lib/aws_fleet.py"
}
