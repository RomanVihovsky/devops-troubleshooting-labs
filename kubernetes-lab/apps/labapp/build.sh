#!/usr/bin/env bash
# Build every labapp tag the scenarios use; optionally push them.
#   apps/labapp/build.sh                         -> labapp:<tag> locally
#   apps/labapp/build.sh registry.lab:5000/lab   -> registry.lab:5000/lab/labapp:<tag>
#   PUSH=1 apps/labapp/build.sh registry.lab:5000/lab
set -euo pipefail
cd "$(dirname "$0")"
prefix=${1:+$1/}
img="${prefix}labapp"

build() { # tag [build-arg ...]
  local tag=$1; shift
  local args=()
  for a in "$@"; do args+=(--build-arg "$a"); done
  docker build -q "${args[@]}" -t "$img:$tag" . >/dev/null
  echo "built $img:$tag"
  if [[ ${PUSH:-0} == 1 ]]; then docker push -q "$img:$tag"; fi
}

build 1.4      APP_VERSION=1.4                              # default, chart appVersion
build 1.3      APP_VERSION=1.3                              # previous release (rollback target)
build 1.5      APP_VERSION=1.5 REQUIRED_ENV=SESSION_SECRET  # broken release: crashloops
build 1.4-root APP_VERSION=1.4 APP_UID=0                    # runs as root (runAsNonRoot scenarios)
build 2.0.0-rc1 APP_VERSION=2.0.0-rc1 REQUIRED_ENV=FEATURE_FLAGS_URL  # bad auto-synced commit: crashes on start
