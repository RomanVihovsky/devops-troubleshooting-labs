# shellcheck shell=bash
# Shared helpers for ./lab and the scenario scripts (setup/verify/solve).
# Everything runs on the HOST and talks to the lab machines via `docker exec`.

LAB_DIR="${LAB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCEN_DIR="$LAB_DIR/scenarios"
STATE_DIR="$LAB_DIR/.state"
IMAGE=linuxlab/server:1
PROJECT=linuxlab
SRV_IP=10.77.0.10
CLIENT_IP=10.77.0.20

mkdir -p "$STATE_DIR"

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

# --------------------------------------------------------------- machines ---
# sx '<bash>'      run a bash snippet as root on lnx-srv
# sxi <<'EOF'      run a bash script (stdin) as root on lnx-srv - nothing is left on disk
# cx / cxi         same on lnx-client
# as_user <user> '<bash>'   run as a user on lnx-srv (login environment)
sx()  { docker exec lnx-srv bash -c "$1"; }
sxi() { docker exec -i lnx-srv bash -s; }
cx()  { docker exec lnx-client bash -c "$1"; }
cxi() { docker exec -i lnx-client bash -s; }
as_user() { docker exec lnx-srv su - "$1" -c "$2"; }

running() { [ "$(docker inspect -f '{{.State.Running}}' "lnx-$1" 2>/dev/null)" = true ]; }

# The disk Docker writes to (used for I/O throttling scenarios).
lab_disk() {
  local src pk
  src=$(df --output=source /var/lib/docker 2>/dev/null | tail -1)
  pk=$(lsblk -ndo PKNAME "$src" 2>/dev/null)
  if [ -n "$pk" ]; then echo "/dev/$pk"; elif [ -b "$src" ]; then echo "$src"; else echo /dev/sda; fi
}

compose() {
  local dir=$1; shift
  if docker compose version >/dev/null 2>&1; then
    (cd "$dir" && LAB_DISK=$(lab_disk) docker compose -p "$PROJECT" "$@")
  else
    # no compose plugin on the host: use the one bundled in docker:29-dind
    docker run --rm -i -v /var/run/docker.sock:/var/run/docker.sock -v "$LAB_DIR:$LAB_DIR" \
      -w "$dir" -e LAB_DISK="$(lab_disk)" --entrypoint docker docker:29-dind \
      compose -p "$PROJECT" "$@"
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

# wait until systemd inside lnx-<host> finished booting
wait_boot() {
  retry "${2:-60}" docker exec "lnx-$1" sh -c \
    'case "$(systemctl is-system-running 2>/dev/null)" in running|degraded) exit 0;; *) exit 1;; esac'
}

# ---------------------------------------------------------------- checks ----
active()   { sx "systemctl is-active --quiet $1"; }
restarts() { sx "systemctl show -p NRestarts --value $1"; }
mainpid()  { sx "systemctl show -p MainPID --value $1"; }
# save / load small facts between setup and verify (kept on the host, not on the server)
remember() { printf '%s' "$2" > "$STATE_DIR/scenario.$1"; }
recall()   { cat "$STATE_DIR/scenario.$1" 2>/dev/null; }

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
  [ -n "${LAB_EXPECT_FAIL:-}" ] && t=3   # selftest: don't wait long for a known-broken state
  check "$desc" retry "$t" "$@"
}
verdict() {
  local t0 el=""
  t0=$(recall started)
  [ -n "$t0" ] && el=" (time since start: $(( ($(date +%s) - t0) / 60 )) min)"
  echo
  if [ "$CHECKS_FAILED" -eq 0 ]; then
    echo "${C_G}${C_BOLD}PASS${C_0} - fixed$el."
    return 0
  fi
  echo "${C_R}${C_BOLD}FAIL${C_0} - $CHECKS_FAILED check(s) failing$el. Keep digging (./lab hint)."
  return 1
}
