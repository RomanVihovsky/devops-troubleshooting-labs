# shellcheck shell=bash disable=SC2034
# Shared helpers for ./lab and the scenario scripts (setup/verify/solve).
# Everything runs on the desktop VM; the cluster lives in sibling VirtualBox VMs reached over SSH
# (lib/vm.sh). ./lab never talks to the hypervisor - the kit (infra/vbox) does that on the host.

LAB_DIR="${LAB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="$LAB_DIR/.state"
CACHE_DIR="$LAB_DIR/cache"
SCEN_DIR="$LAB_DIR/scenarios"
LEARN_DIR="$LAB_DIR/learn"
# shellcheck source=versions.env source-path=SCRIPTDIR/..
source "$LAB_DIR/versions.env"
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
rel()  { echo "${1#"$LAB_DIR"/}"; }   # path relative to the lab folder, for messages

# md <file>: render the bit of markdown we use (headings, **bold**, `code`)
md() {
  sed -e "s/^#\{1,3\} \(.*\)/${C_BOLD}${C_C}\1${C_0}/" \
      -e "s/\*\*\([^*]*\)\*\*/${C_BOLD}\1${C_0}/g" \
      -e "s/\`\([^\`]*\)\`/${C_C}\1${C_0}/g" \
      -e '/^```/d' "$@"
}

# retry <timeout_s> <cmd...>   re-run cmd every 2s until it succeeds or time runs out
retry() {
  local deadline=$((SECONDS + $1)); shift
  until "$@" >/dev/null 2>&1; do
    [ $SECONDS -ge $deadline ] && return 1
    sleep 2
  done
}

# fetch <url> <dest> [sha256]: resumable download with retries, optional checksum
fetch() {
  local url=$1 dest=$2 sum=${3:-} i
  for i in 1 2 3 4 5 6; do
    if curl -fL --retry 3 --retry-delay 3 --connect-timeout 20 -C - -o "$dest.part" "$url"; then
      if [ -n "$sum" ] && ! echo "$sum  $dest.part" | sha256sum -c --quiet - >/dev/null 2>&1; then
        rm -f "$dest.part"; die "checksum mismatch for $url"
      fi
      mv "$dest.part" "$dest"; return 0
    fi
    warn "retry $i for $url"; sleep 5
  done
  return 1
}

# save / load small facts between setup and verify (kept in .state, never in the workspace)
remember() { printf '%s' "$2" > "$STATE_DIR/scenario.$1"; }
recall()   { cat "$STATE_DIR/scenario.$1" 2>/dev/null; }

# ---------------------------------------------------------------- checks ----
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
not() { ! "$@"; }
# check_eventually <timeout_s> <desc> <cmd...>
check_eventually() {
  local t=$1 desc=$2; shift 2
  [ -n "${LAB_EXPECT_FAIL:-}" ] && t=3   # selftest: don't wait long for a known-broken state
  check "$desc" retry "$t" "$@"
}
verdict() {
  echo
  if [ "$CHECKS_FAILED" -eq 0 ]; then echo "${C_G}${C_BOLD}PASS${C_0}"; return 0; fi
  echo "${C_R}${C_BOLD}FAIL${C_0} - $CHECKS_FAILED check(s) failing."; return 1
}
