# shellcheck shell=bash disable=SC2029,SC2016,SC2034,SC2153
# The scenario framework: list/start/ticket/hint/verify/solution/solve/reset/stop/status/diff/selftest
# (house style of ../ansible-lab) + the helpers that scenario scripts use. A scenario is
# scenarios/<ID>-kebab/ (or learn/T..): scenario.yaml, ticket.md, hints.md, [manifests/], .lab/{setup,verify,
# solve}.sh + solution.md. Before a lab starts, the previous one is cleaned up at ITS reset level
# (scenario.yaml reset: ns|node|gw|cluster) - see docs/FAULTS.md.

WS="$LAB_DIR/workspace"
LAB_LABEL=lab.k8slab/scenario
SETUP_LOG="$STATE_DIR/setup.log"
SELFTEST_LOG="$STATE_DIR/selftest.log"

# ------------------------------------------------------------ discovery ----
all_labs() { local d; for d in "$LEARN_DIR"/*/ "$SCEN_DIR"/*/; do [ -f "$d/scenario.yaml" ] && echo "${d%/}"; done; }
yget()  { sed -n "s/^$1: *//p" "$2/scenario.yaml" | head -1 | sed 's/ *#.*//'; }
ylist() { yget "$1" "$2" | tr -d '[],'; }
lab_dir() {
  local id=$1 d u
  for d in "$LEARN_DIR/$id" "$SCEN_DIR/$id"; do [ -d "$d" ] && { echo "$d"; return; }; done
  u=${id^^}
  for d in "$LEARN_DIR/$u"-* "$SCEN_DIR/$u"-*; do [ -d "$d" ] && { echo "$d"; return; }; done
  die "no such lab: $1 (see ./lab list)"
}
current() { [ -f "$STATE_DIR/current" ] || die "no lab running - ./lab start <id>"; echo "$LAB_DIR/$(cat "$STATE_DIR/current")"; }

cmd_list() {
  local filter=${1:-} dom=${2:-} d name id kind lvl title mark cur last=""
  cur=$(cat "$STATE_DIR/current" 2>/dev/null || true)
  while read -r d; do
    name=$(basename "$d"); id=$(yget id "$d"); kind=$(yget kind "$d"); lvl=$(yget level "$d")
    case $filter in
      --learn) [ "$kind" = learn ] || continue ;;
      --incidents) [ "$kind" = incident ] || continue ;;
      --domain) [ "${id:0:1}" = "${dom^^}" ] || continue ;;
    esac
    if [ "$kind" != "$last" ]; then
      echo; if [ "$kind" = learn ]; then echo "${C_BOLD}Learn track${C_0}"; else echo "${C_BOLD}Incidents${C_0}"; fi
      last=$kind
    fi
    title=$(sed -n '1s/^# *//p' "$d/ticket.md"); title=${title#"$id · "}
    mark=' '; grep -qx "$name" "$STATE_DIR/solved" 2>/dev/null && mark="${C_G}✔${C_0}"
    [ "$cur" = "$(rel "$d")" ] && mark="${C_Y}▶${C_0}"
    printf ' %s %-5s %-4s %-8s %s\n' "$mark" "$id" "$(printf '%*s' "${lvl:-1}" '' | sed 's/ /•/g')" "$(yget reset "$d")" "$title"
  done < <(all_labs)
  echo
}

# ---------------------------------------------------------- script runner ----
# run_lab_script <script> <dir> [bash flags]: a scenario script in a subshell with the lab libraries loaded
run_lab_script() {
  local script=$1 dir=$2 flags=${3:--euo pipefail}
  # shellcheck disable=SC2086
  SCN="$(dirname "$(dirname "$script")")" LAB_DIR="$LAB_DIR" LAB_ID="${LAB_ID:-}" bash $flags -c '
    source "$LAB_DIR/lib/common.sh"; source "$LAB_DIR/lib/vm.sh"; source "$LAB_DIR/lib/cluster.sh"
    source "$LAB_DIR/lib/upgrade.sh"; source "$LAB_DIR/lib/golden.sh"; source "$LAB_DIR/lib/gitops.sh"
    source "$LAB_DIR/lib/scenario.sh"
    if [ -f "$STATE_DIR/scenario.env" ]; then set -a; source "$STATE_DIR/scenario.env"; set +a; fi
    case $- in *e*) trap "lab_err_trap \$? \$LINENO" ERR ;; esac
    cd "$2" && source "$1"' _ "$script" "$dir"
}
# set -e scripts (setup/solve) would otherwise die silently on a failing command that is not `die`
lab_err_trap() { echo "✘ line $2: exit $1: ${BASH_COMMAND:0:160}" >&2; }

# --------------------------------------------------------------- helpers ----
# kns <ns>...: namespaces owned by the running scenario (deleted by its cleanup)
# (a namespace of the previous run still Terminating is waited for first - creating "into" it fails later)
ns_gone_or_live() { [ -z "$(kx get namespace "$1" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)" ]; }
kns() {
  local n
  for n in "$@"; do
    retry 240 ns_gone_or_live "$n" || warn "namespace $n is still terminating"
    kx create namespace "$n" --dry-run=client -o yaml | ka -f -
  done
}
# ka -f <file|->: kubectl apply with the scenario label on every object (pod templates untouched).
# (Not "kubectl label --local -o yaml": for a multi-document file it prints the objects without "---".)
ka() {
  [ "${1:-}" = -f ] || die "usage: ka -f <file|->"
  local src=${2:--}; [ "$src" = - ] && src=/dev/stdin
  python3 -c '
import sys, yaml
key, val = sys.argv[1], sys.argv[2]
def label(o):
    if o.get("kind", "").endswith("List") and "items" in o:
        for i in o["items"]: label(i)
    else:
        o.setdefault("metadata", {}).setdefault("labels", {})[key] = val
docs = [d for d in yaml.safe_load_all(sys.stdin) if d]
for d in docs: label(d)
yaml.safe_dump_all(docs, sys.stdout, sort_keys=False)' "$LAB_LABEL" "$LAB_ID" < "$src" | kx apply -f - >/dev/null
}
# deploy_ready <ns> <deploy> [n]: the rollout is complete and n (default spec.replicas) replicas are ready
deploy_ready() {
  local want=${3:-$(kx -n "$1" get deploy "$2" -o jsonpath='{.spec.replicas}' 2>/dev/null)}
  [ -n "$want" ] && [ "$(kx -n "$1" get deploy "$2" -o jsonpath='{.status.readyReplicas}/{.status.updatedReplicas}/{.status.replicas}' 2>/dev/null)" = "$want/$want/$want" ]
}
# has_endpoints <ns> <service>: the Service has at least one ready endpoint
has_endpoints() { [ -n "$(kx -n "$1" get endpointslices -l kubernetes.io/service-name="$2" -o jsonpath='{.items[*].endpoints[?(@.conditions.ready==true)].addresses[0]}' 2>/dev/null)" ]; }
wait_rollout() { kx -n "$1" rollout status "$2" --timeout="${3:-180}s" >/dev/null; }
restarts() { kx -n "$1" get pods -l "$2" -o jsonpath='{range .items[*]}{.status.containerStatuses[*].restartCount}{" "}{end}' | awk '{ for (i = 1; i <= NF; i++) s += $i } END { print s + 0 }'; }
# crashlooping <ns> <selector>: a container waits in CrashLoopBackOff or has failed and restarted at least twice.
# Polling only the waiting reason misses it: between restarts the state is running or terminated.
crashlooping() {
  kx -n "$1" get pods -l "$2" -o json 2>/dev/null | jq -e '[.items[].status.containerStatuses[]?
    | select(.state.waiting.reason == "CrashLoopBackOff" or (.restartCount >= 2 and (.lastState.terminated.exitCode // 0) != 0))]
    | length > 0' >/dev/null
}
# restarted_within <ns> <selector> <seconds>: a container of those pods last terminated less than <seconds> ago
restarted_within() {
  local since; since=$(date -u -d "-$3 seconds" +%FT%TZ)
  kx -n "$1" get pods -l "$2" -o json 2>/dev/null \
    | jq -e --arg s "$since" '[.items[].status.containerStatuses[]?.lastState.terminated.finishedAt // empty | select(. > $s)] | length > 0' >/dev/null
}
# stable_for <seconds> <ns> <selector>: pods Ready, no restart during the last <seconds> and none while we watch.
# The look-back matters: a pod killed every ~40 s (P09, liveness on a wrong port) is Ready between the kills,
# and selftest's broken pass only watches for 3 s.
stable_for() {
  local t=$1 ns=$2 sel=$3 r0
  restarted_within "$ns" "$sel" "$t" && return 1
  [ -n "${LAB_EXPECT_FAIL:-}" ] && t=3
  kx -n "$ns" wait --for=condition=Ready pod -l "$sel" --timeout=60s >/dev/null 2>&1 || return 1
  r0=$(restarts "$ns" "$sel"); sleep "$t"
  [ "$(restarts "$ns" "$sel")" = "$r0" ] && kx -n "$ns" wait --for=condition=Ready pod -l "$sel" --timeout=5s >/dev/null 2>&1
}
# http_code <ns> <url> [header]: HTTP status seen from inside the cluster (a throwaway busybox pod in <ns>). Only
# the status header line counts: on 4xx/5xx busybox wget adds "wget: server returned error: HTTP/1.1 ..."
http_code() {
  local ns=$1 url=$2 hdr=${3:-} pod="lab-probe-$RANDOM" out
  out=$(kx -n "$ns" run "$pod" --rm -i --restart=Never --quiet --image="$BUSYBOX_IMAGE" \
        --labels="$LAB_LABEL=${LAB_ID:-probe}" --command -- \
        sh -c "wget -S -q -O /dev/null -T 5 ${hdr:+--header '$hdr'} '$url' 2>&1 | awk '/^ *HTTP\\//{c=\$2} END{print c+0}'" 2>/dev/null)
  echo "${out:-0}" | tail -1
}
http_ok() { [ "$(http_code "$@")" = 200 ]; }
# tcp_ok_as <ns> <labels|-> <host:port>: a TCP connect from a throwaway agnhost pod that carries <labels>
# (k=v,k2=v2) - the NetworkPolicy view of that workload. Exit 0 = connected.
tcp_ok_as() {
  local ns=$1 lb=$2 tgt=$3 pod="lab-probe-$RANDOM$RANDOM"
  [ "$lb" = - ] && lb=""
  kx -n "$ns" run "$pod" --rm -i --restart=Never --quiet --image="$AGNHOST_IMAGE" \
    --labels="$LAB_LABEL=${LAB_ID:-probe}${lb:+,$lb}" --command -- /agnhost connect --timeout 3s "$tgt" >/dev/null 2>&1
}
# check_reach <<'EOF' ... EOF: one check per row "<ns> <labels|-> <host:port> open|blocked"; the probes run in parallel
check_reach() {
  local d ns lb tgt want r i=0 got; local -a rows=()
  d=$(mktemp -d)
  while read -r ns lb tgt want; do
    case $ns in ''|'#'*) continue ;; esac
    rows+=("$ns $lb $tgt $want"); i=$((i + 1))
    ( if tcp_ok_as "$ns" "$lb" "$tgt"; then echo open; else echo blocked; fi > "$d/$i" ) &
  done
  wait
  i=0
  for r in "${rows[@]}"; do
    i=$((i + 1)); read -r ns lb tgt want <<<"$r"; got=$(cat "$d/$i" 2>/dev/null)
    check "$ns ${lb/#-/(any pod)} -> $tgt: $want" test "$got" = "$want"
  done
  rm -rf "$d"
}
# answer <key>: the student's finding from workspace/<ID>/answers.yaml (trimmed, lower case, "" if missing);
# answered <key> <truth> [alternative...]: it matches the live value or an accepted spelling (case-insensitive)
answer() {
  python3 -c 'import sys, yaml
try: d = yaml.safe_load(open(sys.argv[1])) or {}
except Exception: d = {}
v = d.get(sys.argv[2]) if isinstance(d, dict) else None
print("" if v is None else str(v).strip().lower())' "$WS/$LAB_ID/answers.yaml" "$1" 2>/dev/null
}
answered() {
  local a t; a=$(answer "$1"); shift
  for t in "$@"; do
    t=${t#"${t%%[![:space:]]*}"}; t=${t%"${t##*[![:space:]]}"}
    [ -n "$t" ] && [ "$a" = "${t,,}" ] && return 0
  done
  return 1
}
# pods_get <ns> <selector> <path> [port]: what every Running pod of <selector> answers on localhost:<port><path>
# (`labapp get` inside the pod - labapp images only), one body per line
pods_get() {
  local p
  for p in $(kx -n "$1" get pods -l "$2" --field-selector=status.phase=Running -o name 2>/dev/null); do
    kx -n "$1" exec "$p" -- labapp get "http://localhost:${4:-8080}$3" 2>/dev/null; echo
  done
}
# http_out <url> [Host]: HTTP status from this desktop (LB 192.168.56.200, NodePorts)
http_out() { curl -s -o /dev/null -w '%{http_code}' --max-time 5 ${2:+-H "Host: $2"} "$1"; }
can_i() { local as=$1; shift; [ "$(kx auth can-i --as "$as" "$@" 2>/dev/null)" = yes ]; }
# https_out <host> [path]: HTTPS status from this desktop through the LB (192.168.56.200:443), the served cert
# verified against the lab CA for <host> - 000 = TLS failed (Traefik's default cert, wrong name, other CA)
https_out() { curl -s -o /dev/null -w '%{http_code}' --max-time 5 --cacert "$CA_DIR/ca.crt" --resolve "$1:443:192.168.56.200" "https://$1${2:-/}"; }
LABAPP_IMAGE=registry.lab:5000/lab/labapp:1.4
# load_test <ns> <url> [-c N] [-d S] [--rps N]: `labapp load` from a throwaway pod in <ns> (no API timeout: the
# attach lasts the whole run). Prints the JSON summary {requests, errors, codes, rps, p50_ms, p90_ms, p99_ms,
# max_ms}, or {} when the pod could not run. Read it with jq, e.g. jq .p99_ms
load_test() {
  local ns=$1 url=$2 out; shift 2
  out=$(KX_TIMEOUT='' kx -n "$ns" run "lab-load-$RANDOM$RANDOM" --rm -i --restart=Never --quiet --image="$LABAPP_IMAGE" \
        --labels="$LAB_LABEL=${LAB_ID:-probe},lab.k8slab/role=load" --command -- labapp load "$url" -q "$@" 2>/dev/null | grep '^{' | tail -1)
  echo "${out:-"{}"}"
}
# node_reboot <node> [timeout]: reboot from inside the guest, wait until SSH answers with a new boot id. Not for
# Ready: a reboot-surfacing fault may keep the node NotReady (L14) - the caller decides what "back" means.
boot_id() { nx "$1" 'cat /proc/sys/kernel/random/boot_id' </dev/null 2>/dev/null; }
node_rebooted() { local b; b=$(boot_id "$1") && [ -n "$b" ] && [ "$b" != "$2" ]; }
node_reboot() {
  local n b; n=$(node_name "$1"); b=$(boot_id "$n")
  nx "$n" 'systemctl reboot' </dev/null >/dev/null 2>&1 || true
  sleep 10
  retry "${2:-300}" node_rebooted "$n" "$b"
}
# user_kubeconfig <user> <group[,group..]> <file>: a client cert for <user> from the cluster CA through the CSR
# API (CSR lab-<user>, labelled for cleanup) and a kubeconfig at <file> that uses it - a real teammate (K08, A08)
csr_issued() { [ -n "$(kx get csr "$1" -o jsonpath='{.status.certificate}' 2>/dev/null)" ]; }
user_kubeconfig() {
  local u=$1 f=$3 d g subj="/CN=$1" server; d=$(mktemp -d)
  for g in ${2//,/ }; do subj+="/O=$g"; done
  openssl genrsa -out "$d/key" 2048 2>/dev/null
  openssl req -new -key "$d/key" -subj "$subj" -out "$d/csr"
  kx delete csr "lab-$u" --ignore-not-found >/dev/null 2>&1
  ka -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: lab-$u}
spec:
  request: $(base64 -w0 "$d/csr")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 2592000
  usages: [client auth]
EOF
  kx certificate approve "lab-$u" >/dev/null && retry 30 csr_issued "lab-$u" || { rm -rf "$d"; return 1; }
  kx get csr "lab-$u" -o jsonpath='{.status.certificate}' | base64 -d > "$d/crt"
  kx config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$d/ca"
  server=$(kx config view --minify -o jsonpath='{.clusters[0].cluster.server}')
  rm -f "$f"
  KUBECONFIG=$f kubectl config set-cluster lab --server="$server" --certificate-authority="$d/ca" --embed-certs >/dev/null
  KUBECONFIG=$f kubectl config set-credentials "$u" --client-certificate="$d/crt" --client-key="$d/key" --embed-certs >/dev/null
  KUBECONFIG=$f kubectl config set-context "$u@lab" --cluster=lab --user="$u" --namespace=default >/dev/null
  KUBECONFIG=$f kubectl config use-context "$u@lab" >/dev/null
  chmod 600 "$f"; rm -rf "$d"
}
# fault_partition <node> / fault_clear <node>: cut a node off the cluster network, keep the desktop's SSH
# (it arrives from 192.168.56.1 through the host). Egress matched in POSTROUTING (see docs/FAULTS.md).
fault_partition() {
  nx "$1" 'nft -f - <<EOF
table inet lab_fault
delete table inet lab_fault
table inet lab_fault {
  chain in { type filter hook input priority 0; policy accept;
    ip saddr 192.168.56.1 accept
    ip saddr 192.168.56.0/24 drop
  }
  chain out { type filter hook postrouting priority 200; policy accept;
    ip daddr 192.168.56.1 accept
    ip daddr 192.168.56.0/24 drop
  }
}
EOF' </dev/null
}
fault_clear() { nx "$1" 'nft delete table inet lab_fault 2>/dev/null; true' </dev/null; }
# gitops_commit "<message>" [author]: run the snippet on stdin inside a fresh clone of lab/gitops, push as a colleague
gitops_commit() {
  local msg=$1 who=${2:-dev-bob} w; w=$(mktemp -d)
  git clone -q "http://lab:$(cat "$GITEA_DIR/token")@192.168.56.20:3000/lab/gitops.git" "$w"
  (cd "$w" && bash -euo pipefail)
  git -C "$w" add -A
  git -C "$w" -c user.name="$who" -c user.email="$who@k8s.lab" commit -qm "$msg"
  git -C "$w" push -q origin main 2>/dev/null
  rm -rf "$w"
}
# nodes_normalize: Node objects back to the baseline - uncordoned, zone labels, no taints a person added
# (control-plane and the node controller's own node.kubernetes.io/* taints stay, except out-of-service)
nodes_normalize() {
  local n k
  for n in $(cluster_nodes); do
    kx uncordon "$n" >/dev/null 2>&1
    kx label node "$n" "topology.kubernetes.io/zone=$(zone_of "$n")" --overwrite >/dev/null 2>&1
    for k in $(kx get node "$n" -o json 2>/dev/null | jq -r '.spec.taints[]? | select((.key | startswith("node.kubernetes.io/") | not)
               and .key != "node-role.kubernetes.io/control-plane" or .key == "node.kubernetes.io/out-of-service") | .key'); do
      kx taint node "$n" "$k-" >/dev/null 2>&1
    done
  done
}
argo_refresh() { kx -n argocd annotate application "$1" argocd.argoproj.io/refresh=hard --overwrite >/dev/null; }
argo_sync() { kx -n argocd patch application "$1" --type merge -p '{"operation":{"sync":{"revision":"main","prune":true}}}' >/dev/null; }

# ---------------------------------------------------------------- cleanup ----
# scenario_cleanup <lab dir>: undo what that lab may have changed, at its declared reset level
scenario_cleanup() {
  local d=$1 id level ns nodes kinds
  id=$(yget id "$d"); level=$(yget reset "$d"); level=${level:-ns}
  # optional hook for leftovers outside the ladder (cluster-scoped objects such as CSRs or Retain PVs)
  if [ -f "$d/.lab/cleanup.sh" ] && [ "$level" != cluster ]; then
    local wd="$WS/$id"; [ -d "$wd" ] || wd=$LAB_DIR
    LAB_ID=$id run_lab_script "$d/.lab/cleanup.sh" "$wd" "-u" || warn "$(basename "$d"): cleanup.sh failed"
  fi
  case $level in
    cluster) cluster_reset cluster >/dev/null || return 1; return 0 ;;
    ns|node|gw) ;;
    *) die "$(basename "$d"): unknown reset level '$level'" ;;
  esac
  # GitOps first: while the scenario's apps are still in Git (and self-healing), Argo CD would re-create the
  # namespaces we are about to delete
  [ "$(yget gitops "$d")" = true ] && reset_gitops_baseline
  ns=$(ylist namespaces "$d")
  # shellcheck disable=SC2086
  [ -z "$ns" ] || kx delete namespace $ns --ignore-not-found --wait=false >/dev/null 2>&1
  kinds=$(kx api-resources --verbs=list,delete -o name 2>/dev/null | grep -vE '^(events|events.events.k8s.io|namespaces)$' | paste -sd,)
  kx delete "$kinds" -A -l "$LAB_LABEL=$id" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  # node reset before waiting for the namespaces: pods on a partitioned or broken node can't finish
  # terminating until its kubelet is back (L11/L12)
  if [ "$level" = node ]; then
    nodes=$(ylist nodes "$d")
    for n in $nodes; do n=$(node_name "$n"); reset_node_files "$n" </dev/null; start_kubelets "$n"; done
    retry 180 nodes_ready || warn "not all nodes Ready after the node reset"
    # evictions (R04, R08) leave Failed pods in any namespace - cluster_quick would count them as broken
    kx delete pods -A --field-selector=status.phase=Failed --wait=false >/dev/null 2>&1
  fi
  if [ -n "$ns" ]; then
    # shellcheck disable=SC2086
    kx wait --for=delete namespace $ns --timeout=120s >/dev/null 2>&1 || warn "namespace(s) $ns still terminating"
  fi
  # Node objects are shared: cordons, taints, a deleted + re-registered node (zone label) - always normalise
  nodes_normalize
  [ "$level" = gw ] && reset_gw </dev/null
  # openbao: true = kv paths, policies or auth roles changed -> the golden raft snapshot (gw already did it)
  if [ "$(yget openbao "$d")" = true ] && [ "$level" != gw ]; then reset_openbao || return 1; fi
  return 0
}

# ------------------------------------------------------------- lifecycle ----
cmd_stop() {
  local d
  if [ -f "$STATE_DIR/current" ]; then
    d=$(current)
    info "cleaning up $(basename "$d") (reset: $(yget reset "$d"))"
    scenario_cleanup "$d" || warn "cleanup of $(basename "$d") failed"
  fi
  rm -rf "${WS:?}"/*/ 2>/dev/null; mkdir -p "$WS"
  rm -f "$STATE_DIR/current" "$STATE_DIR/hint" "$STATE_DIR"/scenario.* "$SETUP_LOG"
}

show_ticket() {
  echo; md "$1/ticket.md"
  cat <<EOF

${C_BOLD}Work${C_0}: eval "\$(./lab env)" (kubectl, helm, argocd, kubeseal, bao) · ./lab node <n> · workspace/$(yget id "$1")/
${C_BOLD}Check${C_0}: ./lab verify   ${C_BOLD}Stuck?${C_0} ./lab hint
EOF
}

cmd_start() {
  local d name id
  [ $# -ge 1 ] || die "usage: ./lab start <id|random>"
  ensure_tools
  if [ "$1" = random ]; then d=$(all_labs | while read -r x; do [ "$(yget kind "$x")" = incident ] && echo "$x"; done | shuf -n1)
  else d=$(lab_dir "$1"); fi
  name=$(basename "$d"); id=$(yget id "$d")
  cmd_stop
  if ! cluster_quick; then
    warn "the cluster is not in its baseline shape - cluster reset"
    cluster_reset cluster >/dev/null || die "cluster reset failed - ./lab cluster doctor"
    cluster_quick || die "cluster still unhealthy after a reset - ./lab cluster doctor"
  fi
  if [ "$1" = random ]; then info "Starting a random incident..."; else info "Starting ${C_BOLD}$name${C_0}..."; fi
  rel "$d" > "$STATE_DIR/current"
  mkdir -p "$WS/$id"
  [ -d "$d/manifests" ] && cp -a "$d/manifests/." "$WS/$id/"
  [ "$(yget gitops "$d")" = true ] && gitops_clone >/dev/null
  : > "$SETUP_LOG"
  export LAB_ID=$id
  if [ -f "$d/.lab/setup.sh" ]; then
    run_lab_script "$d/.lab/setup.sh" "$WS/$id" >> "$SETUP_LOG" 2>&1 || { tail -15 "$SETUP_LOG" >&2; die "setup failed (log: .state/setup.log)"; }
  fi
  # "as found" = what the student gets, including files setup wrote (./lab diff shows only their changes)
  git -C "$WS/$id" init -q 2>/dev/null; git -C "$WS/$id" add -A
  git -C "$WS/$id" -c user.name=lab -c user.email=lab@k8s.lab commit -qm "as found" --allow-empty
  remember started "$(date +%s)"
  show_ticket "$d"
}

cmd_ticket() { show_ticket "$(current)"; }

cmd_hint() {
  local d n total
  d=$(current); total=$(grep -c '^## ' "$d/hints.md")
  if [ $# -ge 1 ]; then n=$1; else n=$(( $(cat "$STATE_DIR/hint" 2>/dev/null || echo 0) + 1 )); fi
  [ "$n" -gt "$total" ] && n=$total
  echo "$n" > "$STATE_DIR/hint"
  echo "${C_BOLD}Hint $n/$total${C_0}"
  awk -v n="$n" '/^## /{i++; next} i==n' "$d/hints.md" | md
  [ "$n" -lt "$total" ] && echo "${C_C}(./lab hint for the next one)${C_0}"
  return 0
}

cmd_verify() {
  local d rc=0
  d=$(current); export LAB_ID; LAB_ID=$(yget id "$d")
  info "Verifying $(basename "$d")"
  # house rule: verify runs with -u but WITHOUT pipefail (kubectl | grep -q races)
  KX_TIMEOUT=10s run_lab_script "$d/.lab/verify.sh" "$WS/$LAB_ID" "-u" || rc=$?
  if [ $rc -eq 0 ] && [ -z "${LAB_SELFTEST:-}" ]; then
    grep -qx "$(basename "$d")" "$STATE_DIR/solved" 2>/dev/null || basename "$d" >> "$STATE_DIR/solved"
  fi
  return $rc
}

cmd_solution() {
  local d a; d=$(current)
  if [ -t 0 ] && [ "${1:-}" != -y ]; then
    read -r -p "Show the solution for $(basename "$d")? This is a spoiler. [y/N] " a
    [[ $a =~ ^[yY] ]] || exit 0
  fi
  md "$d/.lab/solution.md"
}

cmd_solve() {
  local d; d=$(current); export LAB_ID; LAB_ID=$(yget id "$d")
  info "Applying the reference fix for $(basename "$d")"
  run_lab_script "$d/.lab/solve.sh" "$WS/$LAB_ID"
}

cmd_reset() { local d; d=$(current); cmd_start "$(basename "$d")"; }

cmd_diff() {
  local d id; d=$(current); id=$(yget id "$d")
  git -C "$WS/$id" -c color.ui=always diff HEAD -- . || true
  git -C "$WS/$id" status --short --untracked-files=all | grep '^??' || true
}

cmd_status() {
  if [ -f "$STATE_DIR/current" ]; then
    local d; d=$(current)
    echo "lab: $(basename "$d") (reset: $(yget reset "$d"), started $(( ($(date +%s) - $(recall started)) / 60 )) min ago, hints used: $(cat "$STATE_DIR/hint" 2>/dev/null || echo 0))"
  else
    echo "lab: none"
  fi
}

# --------------------------------------------------------------- selftest ----
cmd_selftest() {
  local targets=() d name t0 broken fixed results=() sel=${1:-all}
  case $sel in
    all) mapfile -t targets < <(all_labs) ;;
    learn|incidents) while read -r d; do [ "$(yget kind "$d")" = "${sel%s}" ] && targets+=("$d"); done < <(all_labs) ;;
    pilots) while read -r d; do [ "$(yget pilot "$d")" = true ] && targets+=("$d"); done < <(all_labs) ;;
    wave*) while read -r d; do [ "$(yget wave "$d")" = "${sel#wave}" ] && targets+=("$d"); done < <(all_labs) ;;
    *) for d in "$@"; do targets+=("$(lab_dir "$d")"); done ;;
  esac
  [ ${#targets[@]} -gt 0 ] || die "nothing to test for '$sel'"
  export LAB_SELFTEST=1
  # every result line also goes to .state/selftest.log as it happens (survives a killed run / a reboot)
  echo "== $(date -u +%FT%TZ) selftest ${*:-all}" >> "$SELFTEST_LOG"
  for d in "${targets[@]}"; do
    name=$(basename "$d"); t0=$SECONDS
    echo; info "${C_BOLD}selftest $name${C_0}"
    if ! ( cmd_start "$name" ) >/dev/null; then
      # keep the setup log: the next start (or the final stop) clears .state/setup.log
      cp -f "$SETUP_LOG" "$STATE_DIR/selftest-setup-$name.log" 2>/dev/null
      results+=("$(printf '%-36s SETUP FAILED %5ss  (.state/selftest-setup-%s.log)' "$name" $((SECONDS - t0)) "$name")")
      echo "  ${results[-1]}" >> "$SELFTEST_LOG"; continue
    fi
    broken=ok; ( LAB_EXPECT_FAIL=1 cmd_verify ) >/dev/null 2>&1 && broken="NOT BROKEN"
    ( cmd_solve ) >/dev/null 2>&1 || true
    fixed=ok; ( cmd_verify ) || fixed="NOT FIXED"
    results+=("$(printf '%-36s broken:%-10s fixed:%-10s %5ss' "$name" "$broken" "$fixed" $((SECONDS - t0)))")
    echo "  ${results[-1]}" >> "$SELFTEST_LOG"
  done
  cmd_stop
  echo "== $(date -u +%FT%TZ) done" >> "$SELFTEST_LOG"
  echo; echo "${C_BOLD}Selftest results${C_0}"; printf '  %s\n' "${results[@]}"
  printf '%s\n' "${results[@]}" | grep -qE 'NOT |FAILED' && return 1 || return 0
}
