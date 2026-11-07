# shellcheck shell=bash
# Shared helpers for ./lab and the scenario scripts (setup/verify/solve).
# Everything runs on the HOST and talks to the node containers via `docker exec`.

LAB_DIR="${LAB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCEN_DIR="$LAB_DIR/scenarios"
WORK_DIR="$LAB_DIR/workspace"
STATE_DIR="$LAB_DIR/.state"
STACK=app
NODE_IMAGE=swarmlab/node:1
REGISTRY=registry:5000
# host image -> path inside the lab registry. ./lab up seeds these (no Docker Hub at runtime).
SEED_IMAGES=(
  "swarmlab/webapp:1.0 lab/webapp:1.0"
  "redis:7-alpine redis:7-alpine"
  "nginx:1.27-alpine nginx:1.27-alpine"
  "alpine:3.20 alpine:3.20"
)
BASE_IMAGES=("$REGISTRY/lab/webapp:1.0" "$REGISTRY/redis:7-alpine" "$REGISTRY/nginx:1.27-alpine" "$REGISTRY/alpine:3.20")
BASE_NODES=(manager1 worker1 worker2)
HA_NODES=(manager2 manager3)
APP_PORT=8080

mkdir -p "$STATE_DIR/undo" "$WORK_DIR"

# ---------------------------------------------------------------- output ----
if [ -t 1 ]; then
  C_R=$'\e[31m' C_G=$'\e[32m' C_Y=$'\e[33m' C_B=$'\e[34m' C_C=$'\e[36m' C_BOLD=$'\e[1m' C_0=$'\e[0m'
else
  C_R='' C_G='' C_Y='' C_B='' C_C='' C_BOLD='' C_0=''
fi
info() { echo "${C_B}==>${C_0} $*"; }
ok()   { echo "${C_G}✔${C_0} $*"; }
warn() { echo "${C_Y}!${C_0} $*" >&2; }
die()  { echo "${C_R}✘ $*${C_0}" >&2; exit 1; }

# ----------------------------------------------------------------- nodes ----
# nx <node> <cmd...>     run a command inside a node ("VM")
# nsh <node> '<script>'  run a shell snippet inside a node
# dk <docker args...>    run the docker CLI on manager1 (the swarm control plane)
nx()  { docker exec "lab-$1" "${@:2}"; }
nsh() { docker exec "lab-$1" sh -c "$2"; }
dk()  { docker exec lab-manager1 docker "$@"; }
dkn() { docker exec "lab-$1" docker "${@:2}"; }

node_exists()  { docker inspect "lab-$1" >/dev/null 2>&1; }
node_running() { [ "$(docker inspect -f '{{.State.Running}}' "lab-$1" 2>/dev/null)" = "true" ]; }
node_ip() { docker inspect -f '{{(index .NetworkSettings.Networks "swarmlab").IPAddress}}' "lab-$1"; }
lab_nodes() {
  docker ps --filter label=com.docker.compose.project=swarmlab --format '{{.Names}}' \
    | sed -n 's/^lab-\(manager[0-9]*\|worker[0-9]*\)$/\1/p' | sort
}

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$LAB_DIR/infra/compose.yml" "$@"
  else
    # No compose plugin on the host: use the one bundled in the node image.
    docker run --rm -i -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$LAB_DIR:$LAB_DIR" -w "$LAB_DIR/infra" --entrypoint docker "$NODE_IMAGE" \
      compose -f "$LAB_DIR/infra/compose.yml" "$@"
  fi
}

# retry <timeout_s> <cmd...>   re-run cmd every 2s until it succeeds or time runs out
retry() {
  local deadline=$((SECONDS + $1)); shift
  until "$@" >/dev/null 2>&1; do
    [ $SECONDS -ge $deadline ] && return 1
    sleep 2
  done
}

wait_dockerd() { retry "${2:-60}" docker exec "lab-$1" docker info; }

# --------------------------------------------------------------- faults -----
# inject <node> '<do script>' '<undo script>'
# Runs the fault inside the node and records how to undo it (used by reset).
inject() {
  nsh "$1" "$2"
  printf '%s\n' "$3" >> "$STATE_DIR/undo/$1.sh"
}

undo_faults() {
  local f n
  for f in "$STATE_DIR"/undo/*.sh; do
    [ -e "$f" ] || continue
    n=$(basename "$f" .sh)
    if [ "$n" = host ]; then
      bash "$f" >/dev/null 2>&1 || true
    elif node_running "$n"; then
      # undo in reverse order, ignore errors (the user may have fixed it already)
      tac "$f" | while IFS= read -r line; do nsh "$n" "$line" >/dev/null 2>&1 || true; done
    fi
    rm -f "$f"
  done
}

# ---------------------------------------------------------------- swarm -----
svc() { echo "${STACK}_$1"; }

# replicas "app_web" -> "2/3"
replicas() { dk service ls --filter "name=$1" --format '{{.Name}} {{.Replicas}}' | awk -v n="$1" '$1==n{print $2}'; }

svc_converged() {
  local r; r=$(replicas "$1")
  [ -n "$r" ] && [ "${r%%/*}" = "${r#*/}" ] && [ "${r#*/}" != 0 ]
}

# Nodes that currently run a task of the service (state Running).
svc_nodes() {
  dk service ps "$1" --filter desired-state=running --format '{{.Node}} {{.CurrentState}}' \
    | awk '$2=="Running"{print $1}' | sort -u
}

running_tasks() {
  dk service ps "$1" --filter desired-state=running --format '{{.CurrentState}}' | grep -c '^Running' || true
}

# container id of a running task of service $2 on node $1
task_container() {
  dkn "$1" ps -q --filter "label=com.docker.swarm.service.name=$2" --filter status=running | head -1
}

nodes_ready() {
  local want=$1 n
  n=$(dk node ls --format '{{.Status}} {{.Availability}}' 2>/dev/null | grep -c '^Ready Active' || true)
  [ "$n" -ge "$want" ]
}

deploy_stack() {
  dk stack deploy --detach=true -c /lab/workspace/stack.yml "$STACK" >/dev/null
}

# http <node> <path> [curl args...]   GET http://<node-ip>:8080<path> from the host
http() {
  local ip; ip=$(node_ip "$1")
  curl -fsS --max-time "${HTTP_TIMEOUT:-4}" "${@:3}" "http://$ip:$APP_PORT$2"
}

# --------------------------------------------------------------- verify -----
CHECKS_FAILED=0
check() {
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ${C_G}✔${C_0} $desc"
  else
    echo "  ${C_R}✘${C_0} $desc"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
  fi
}
# check_eventually <timeout_s> <desc> <cmd...>
check_eventually() {
  local t=$1 desc=$2; shift 2
  [ -n "${LAB_EXPECT_FAIL:-}" ] && t=4   # selftest: don't wait long for a known-broken state
  check "$desc" retry "$t" "$@"
}
verdict() {
  echo
  if [ "$CHECKS_FAILED" -eq 0 ]; then
    echo "${C_G}${C_BOLD}PASS${C_0} - scenario solved."
    return 0
  fi
  echo "${C_R}${C_BOLD}FAIL${C_0} - $CHECKS_FAILED check(s) failing. Keep digging (./lab hint)."
  return 1
}

# all_nodes_http <path> <grep-pattern> [tries]
# Each node's published port must answer <tries> times in a row with a body matching pattern.
all_nodes_http() {
  local path=$1 pat=$2 tries=${3:-6} n i
  for n in "${BASE_NODES[@]}"; do
    for ((i = 0; i < tries; i++)); do
      http "$n" "$path" | grep -q "$pat" || return 1
    done
  done
}

svc_task_ids() { dk service ps "$1" --filter desired-state=running -q | sort; }
# svc_stable <svc> [seconds]: converged, and no task got replaced during the window
svc_stable() {
  local a b
  svc_converged "$1" || return 1
  a=$(svc_task_ids "$1"); sleep "${2:-20}"
  svc_converged "$1" || return 1
  b=$(svc_task_ids "$1"); [ "$a" = "$b" ]
}
svc_on_all_nodes() { [ "$(svc_nodes "$1" | wc -l)" -ge "${2:-3}" ]; }
# ws_sed '<sed expr>': edit workspace/stack.yml in place (used by solve scripts)
ws_sed() { sed -i "$@" "$WORK_DIR/stack.yml"; }

join_node() {  # join_node <node> <worker|manager>
  local n=$1 role=$2 token
  [ "$(dkn "$n" info -f '{{.Swarm.LocalNodeState}}')" = active ] && return 0
  token=$(dk swarm join-token -q "$role")
  info "Joining $n as $role"
  dkn "$n" swarm join --token "$token" --advertise-addr "$(node_ip "$n")" 172.30.0.11:2377 >/dev/null
}

# force_update <svc> [timeout]: rolling restart that BLOCKS until the update completed
# (with --detach, replicas still read N/N before the update even started)
force_update() { timeout "${2:-180}" docker exec lab-manager1 docker service update --force --quiet "$1" >/dev/null 2>&1; }
