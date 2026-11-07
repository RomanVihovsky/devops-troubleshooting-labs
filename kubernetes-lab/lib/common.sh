# shellcheck shell=bash
# Shared helpers for ./lab (runs on the host).
LAB_DIR="${LAB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STATE_DIR="$LAB_DIR/.state"
mkdir -p "$STATE_DIR"
if [ -t 1 ]; then C_R=$'\e[31m' C_G=$'\e[32m' C_Y=$'\e[33m' C_B=$'\e[34m' C_BOLD=$'\e[1m' C_0=$'\e[0m'; else C_R='' C_G='' C_Y='' C_B='' C_BOLD='' C_0=''; fi
info() { echo "${C_B}==>${C_0} $*"; }
ok()   { echo "${C_G}✔${C_0} $*"; }
warn() { echo "${C_Y}!${C_0} $*" >&2; }
die()  { echo "${C_R}✘ $*${C_0}" >&2; exit 1; }
retry() { local deadline=$((SECONDS + $1)); shift; until "$@" >/dev/null 2>&1; do [ $SECONDS -ge $deadline ] && return 1; sleep 3; done; }
