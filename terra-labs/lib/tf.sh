# shellcheck shell=bash
# Terraform / Terragrunt / AWS (moto) / docker / git helpers. Sourced after lib/common.sh.
#
# Conventions for scenario scripts (.lab/setup.sh, verify.sh, solve.sh):
#   $WS          the student's repo (workspace/), a git repo; "as found" = the commit made after setup
#   tf <dir> ... terraform -chdir=$WS/<dir> ...           (setup/solve: act like the student)
#   tg <dir> ... terragrunt in $WS/<dir>, non-interactive
#   apply <dir>  init + apply, quiet, dies with a log tail on failure
#   aws ...      aws-cli, already pointed at moto
#   verify.sh judges a fresh "CI checkout" of the workspace ($CI), never the student's .terraform/

CI="$STATE_DIR/ci"
SETUP_LOG="$STATE_DIR/setup.log"
VERIFY_LOG="$STATE_DIR/verify.log"
REGISTRY_URL="https://git.acme.example"     # fake corporate git host -> .state/git/*.git

# --------------------------------------------------------- environment ----
# lab_env: everything a lab shell / script needs. The real cloud is unreachable by construction:
# dummy keys, every AWS endpoint -> moto, isolated AWS config files, no profiles.
lab_env() {
  export PATH="$CACHE_DIR/bin:$PATH"
  export TF_CLI_CONFIG_FILE="$STATE_DIR/terraformrc"
  export CHECKPOINT_DISABLE=1
  export TG_TF_PATH=terraform
  unset AWS_PROFILE AWS_DEFAULT_PROFILE AWS_SESSION_TOKEN AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE
  export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
  export AWS_REGION=eu-central-1 AWS_DEFAULT_REGION=eu-central-1
  export AWS_ENDPOINT_URL="$MOTO_URL"
  export AWS_CONFIG_FILE="$STATE_DIR/aws/config" AWS_SHARED_CREDENTIALS_FILE="$STATE_DIR/aws/credentials"
  export AWS_PAGER="" AWS_EC2_METADATA_DISABLED=true
  export GIT_CONFIG_GLOBAL="$STATE_DIR/gitconfig" GIT_TERMINAL_PROMPT=0
  export NO_PROXY="localhost,.localhost,127.0.0.1,::1${NO_PROXY:+,$NO_PROXY}"
  export no_proxy="$NO_PROXY"
  export TERRALAB=1
  export TERRALAB_PROVIDER_MIRROR="$CACHE_DIR/providers"   # for terraform providers lock -fs-mirror=...
  # per-lab environment (e.g. a vendor API key "provided" to the team), written by setup via lab_setenv
  # shellcheck disable=SC1091
  if [ -f "$STATE_DIR/scenario.env" ]; then set -a; source "$STATE_DIR/scenario.env"; set +a; fi
}
# lab_setenv NAME VALUE: export NAME for the student's ./lab sh, ./lab env and for verify
lab_setenv() { printf '%s=%q\n' "$1" "$2" >> "$STATE_DIR/scenario.env"; export "$1=$2"; }

# write_configs: CLI configs that live in .state (never in $HOME)
write_configs() {
  mkdir -p "$STATE_DIR/aws" "$STATE_DIR/git" "$CACHE_DIR/plugin-cache"
  sed "s|@LAB_DIR@|$LAB_DIR|g" "$LAB_DIR/infra/terraformrc.tpl" > "$STATE_DIR/terraformrc"
  : > "$STATE_DIR/aws/credentials"
  printf '[default]\nregion = eu-central-1\ncli_pager =\n' > "$STATE_DIR/aws/config"
  cat > "$STATE_DIR/gitconfig" <<EOF
[user]
	name = You
	email = you@acme.example
[init]
	defaultBranch = main
[advice]
	detachedHead = false
[protocol "file"]
	allow = always
[url "file://$STATE_DIR/git/"]
	insteadOf = $REGISTRY_URL/
EOF
}

# ---------------------------------------------------------------- moto -----
moto_healthy() { curl -fs --max-time 2 "$MOTO_URL/moto-api/" >/dev/null; }
moto_up() {
  moto_healthy && return 0
  docker rm -f "$MOTO_CTR" >/dev/null 2>&1 || true
  docker run -d --name "$MOTO_CTR" --label terralab.infra=moto --memory 512m \
    -p "127.0.0.1:$MOTO_PORT:5000" "$MOTO_IMAGE" >/dev/null
  retry 30 moto_healthy || die "moto did not come up (docker logs $MOTO_CTR)"
}
# empty AWS account in a second
moto_reset() { curl -fsS -X POST "$MOTO_URL/moto-api/reset" >/dev/null; }

# -------------------------------------------------------------- docker -----
# Everything Terraform creates in docker carries label terralab.scenario=<id> and a tfl- name.
docker_reset() {
  { docker ps -a --filter label=terralab.scenario --format '{{.Names}}'
    docker ps -a --format '{{.Names}}' | grep '^tfl-' | grep -vxE "$MOTO_CTR|tfl-pg" || true
  } | sort -u | grep . | xargs -r docker rm -f >/dev/null 2>&1 || true
  { docker network ls --filter label=terralab.scenario --format '{{.Name}}'
    docker network ls --format '{{.Name}}' | grep '^tfl-' || true
  } | sort -u | grep . | xargs -r docker network rm >/dev/null 2>&1 || true
  { docker volume ls --filter label=terralab.scenario --format '{{.Name}}'
    docker volume ls --format '{{.Name}}' | grep '^tfl-' || true
  } | sort -u | grep . | xargs -r docker volume rm >/dev/null 2>&1 || true
}
ctr_id()      { docker inspect -f '{{.Id}}' "$1" 2>/dev/null; }
ctr_running() { [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = true ]; }
# remember_ctr <name> / same_ctr <name>: prove a container was not destroyed and recreated
remember_ctr() { remember "ctr.$1" "$(ctr_id "$1")"; }
same_ctr()     { [ -n "$(recall "ctr.$1")" ] && [ "$(ctr_id "$1")" = "$(recall "ctr.$1")" ]; }

# ----------------------------------------------------------- workspace -----
ws_reset() {
  rm -rf "$WS" "$CI"
  mkdir -p "$WS"
  git -C "$WS" init -q -b main
}
# ws_commit "<msg>" [author] - commit everything (history the student can read with git log)
ws_commit() {
  local who=${2:-"Platform Team"}
  git -C "$WS" add -A
  git -C "$WS" -c user.name="$who" -c user.email="platform@acme.example" commit -q --allow-empty -m "$1"
}
# untouched <path...>: unchanged since "as found" (tracked and untracked files)
untouched() {
  git -C "$WS" diff --quiet "$(recall asfound)" -- "$@" &&
    [ -z "$(git -C "$WS" ls-files --others --exclude-standard -- "$@")" ]
}
# ws_has <ERE>: pattern appears in the workspace's code (tf, hcl, tfvars, scripts, CI files)
ws_has() {
  grep -rqsE --include='*.tf' --include='*.hcl' --include='*.tfvars' --include='*.sh' --include='*.yml' \
    --exclude-dir=.terraform --exclude-dir=.terragrunt-cache --exclude-dir=.git -e "$1" "$WS"
}

# ------------------------------------------------- module "registry" (git) -
# publish <repo> <tag> <src_dir> [message]
#   Commit the content of src_dir as the next version of $REGISTRY_URL/platform/<repo>.git, tag it.
publish() {
  local repo=$1 tag=$2 src=$3 msg=${4:-"release $2"} bare tmp
  bare="$STATE_DIR/git/platform/$repo.git"
  [ -d "$bare" ] || { mkdir -p "$(dirname "$bare")"; git init -q --bare -b main "$bare"; }
  tmp=$(mktemp -d)
  git clone -q "$bare" "$tmp/r" 2>/dev/null
  find "$tmp/r" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp -a "$src"/. "$tmp/r"/
  git -C "$tmp/r" add -A
  git -C "$tmp/r" -c user.name="Module Maintainers" -c user.email="modules@acme.example" \
    commit -q --allow-empty -m "$msg"
  [ "$tag" = - ] || git -C "$tmp/r" tag "$tag"
  git -C "$tmp/r" push -q origin main --tags
  rm -rf "$tmp"
}

# run_lab_script <script> <dir> [bash flags]: run a scenario script in a NEW bash process with the
# lab libraries loaded. A new process is needed because bash ignores `set -e` inside anything that is
# itself part of an `if`/`||` - a failing setup would otherwise be silently swallowed.
run_lab_script() {
  local script=$1 dir=$2 flags=${3:--euo pipefail}
  # shellcheck disable=SC2016,SC2086
  # SCN = the scenario's own directory (for "before" versions of code in .lab/)
  SCN="$(dirname "$(dirname "$script")")" LAB_DIR="$LAB_DIR" bash $flags -c '
    source "$LAB_DIR/lib/common.sh"; source "$LAB_DIR/lib/tf.sh"; lab_env
    cd "$2" && source "$1"' _ "$script" "$dir"
}

# ------------------------------------------------------------ terraform ----
# run_logged <log> <cmd...>: run quietly; on failure show the tail of the log
run_logged() {
  local log=$1; shift
  echo "+ $*" >> "$log"
  if ! "$@" >> "$log" 2>&1; then
    echo "${C_R}command failed:${C_0} $*" >&2
    tail -25 "$log" | sed 's/^/    /' >&2
    return 1
  fi
}
tf() { local d=$1; shift; terraform -chdir="$WS/$d" "$@"; }
tg() { local d=$1; shift; (cd "$WS/$d" && terragrunt --non-interactive --log-level error "$@"); }
# apply <dir> [extra apply args]: init + apply as the "past" team did
apply() {
  local d=$1; shift
  run_logged "$SETUP_LOG" tf "$d" init -input=false -no-color &&
    run_logged "$SETUP_LOG" tf "$d" apply -auto-approve -input=false -no-color "$@"
}
destroy() {
  local d=$1; shift
  run_logged "$SETUP_LOG" tf "$d" destroy -auto-approve -input=false -no-color "$@"
}
tg_apply_all() {
  local d=$1; shift
  run_logged "$SETUP_LOG" tg "$d" run --all -- apply -auto-approve -input=false -no-color "$@"
}

# ------------------------------------------------- verify: CI checkout -----
# ci_checkout: fresh copy of the workspace (with .git, without .terraform/.terragrunt-cache) -
# what a pipeline would see. Called by ./lab verify before verify.sh.
ci_checkout() {
  rm -rf "$CI"; mkdir -p "$CI"
  tar -C "$WS" --exclude=.terraform --exclude=.terragrunt-cache --exclude=.terragrunt-stack \
    -cf - . | tar -C "$CI" -xf -
  : > "$VERIFY_LOG"
}
ci_tf() { local d=$1; shift; terraform -chdir="$CI/$d" "$@"; }
# CI_INIT_ARGS[<dir>]="-backend-config=backend.hcl"  (set in verify.sh for partial backend configs)
# CI_PLAN_ARGS[<dir>]="-var-file=env/staging.tfvars"
declare -A _CI_INIT=() _CI_PLAN=() CI_INIT_ARGS=() CI_PLAN_ARGS=()
ci_init() {
  [ -n "${_CI_INIT[$1]:-}" ] && return "${_CI_INIT[$1]}"
  local rc=0
  # shellcheck disable=SC2086
  run_logged "$VERIFY_LOG" ci_tf "$1" init -input=false -no-color -lock-timeout="${LAB_LOCK_TIMEOUT:-10s}" \
    ${CI_INIT_ARGS[$1]:-} 2>/dev/null || rc=$?
  _CI_INIT[$1]=$rc
  return $rc
}
# plan_rc <dir>: 0 = converged, 2 = changes pending, 1 = error   (cached per verify run)
# Exit code 2 is double-checked against the plan JSON: data sources inside `check` blocks are always
# re-read "during apply", which makes -detailed-exitcode say 2 although nothing would change.
plan_rc() {
  if [ -z "${_CI_PLAN[$1]:-}" ]; then
    local rc=0 pf
    pf="$CI/.lab-${1//\//_}.tfplan"
    if ci_init "$1"; then
      echo "+ plan $1" >> "$VERIFY_LOG"
      # shellcheck disable=SC2086
      ci_tf "$1" plan -detailed-exitcode -input=false -no-color -lock-timeout="${LAB_LOCK_TIMEOUT:-10s}" \
        -out="$pf" ${CI_PLAN_ARGS[$1]:-} >> "$VERIFY_LOG" 2>&1 || rc=$?
      if [ "$rc" = 2 ] && [ "$(real_changes "$1" "$pf")" = 0 ]; then
        echo "  (only deferred data source reads - counts as no changes)" >> "$VERIFY_LOG"
        rc=0
      fi
    else
      rc=1
    fi
    _CI_PLAN[$1]=$rc
  fi
  echo "${_CI_PLAN[$1]}"
}
# real_changes <dir> <planfile>: number of resource/output changes other than no-op and data reads
real_changes() {
  ci_tf "$1" show -json "$2" 2>/dev/null | jq '
    ([.resource_changes[]? | select(.mode == "managed") | .change.actions | select(. != ["no-op"])] | length)
    + ([.output_changes[]? | .actions | select(. != ["no-op"])] | length)'
}
plan_clean() { [ "$(plan_rc "$1")" = 0 ]; }
plan_ok()    { [ "$(plan_rc "$1")" != 1 ]; }     # plans without errors (changes allowed)
state_list() { ci_init "$1" >/dev/null 2>&1 && ci_tf "$1" state list 2>>"$VERIFY_LOG"; }
# state_has_re <dir> <ERE>: some address in state matches (student-chosen names)
state_has_re() { state_list "$1" | grep -qE "$2"; }
in_state()     { state_list "$1" | grep -qxF "$2"; }
not_in_state() { ci_init "$1" && ! state_list "$1" | grep -qxF "$2"; }

# tg_plan_rc <dir>: run --all plan in the CI checkout (0 / 2 / 1 like plan_rc)
tg_plan_rc() {
  local key="tg:$1" rc=0
  if [ -z "${_CI_PLAN[$key]:-}" ]; then
    echo "+ terragrunt run --all plan in $1" >> "$VERIFY_LOG"
    (cd "$CI/$1" && terragrunt run --all --non-interactive --log-level error --no-color -- \
      plan -detailed-exitcode -input=false -no-color -lock-timeout="${LAB_LOCK_TIMEOUT:-10s}") >> "$VERIFY_LOG" 2>&1 || rc=$?
    _CI_PLAN[$key]=$rc
  fi
  echo "${_CI_PLAN[$key]}"
}
tg_plan_clean() { [ "$(tg_plan_rc "$1")" = 0 ]; }

# ------------------------------------------------------------- AWS facts ---
# state_bucket [name]: the versioned state bucket the "platform team" created long ago
state_bucket() {
  local b=${1:-acme-tfstate}
  aws s3api create-bucket --bucket "$b" --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
  aws s3api put-bucket-versioning --bucket "$b" --versioning-configuration Status=Enabled
}
bucket_ctime() { aws s3api list-buckets --query "Buckets[?Name=='$1'].CreationDate" --output text 2>/dev/null; }
remember_bucket() { remember "bucket.$1" "$(bucket_ctime "$1")"; }
same_bucket()     { [ -n "$(recall "bucket.$1")" ] && [ "$(bucket_ctime "$1")" = "$(recall "bucket.$1")" ]; }
bucket_exists() { aws s3api head-bucket --bucket "$1" >/dev/null 2>&1; }
object_exists() { aws s3api head-object --bucket "$1" --key "$2" >/dev/null 2>&1; }
s3_cat()        { aws s3 cp "s3://$1/$2" - 2>/dev/null; }
# no_string_in_s3_state <bucket> <key> <string>
not_in_s3_object() { ! s3_cat "$1" "$2" | grep -qF -- "$3"; }
s3_state_lineage() { s3_cat "$1" "$2" | jq -r .lineage; }
ssm_value() { aws ssm get-parameter --name "$1" --with-decryption --query Parameter.Value --output text 2>/dev/null; }
