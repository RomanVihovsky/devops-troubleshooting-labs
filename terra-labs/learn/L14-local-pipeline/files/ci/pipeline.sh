#!/usr/bin/env bash
# Pipeline for stacks/catalog-api. CI runs exactly this script - so can you.
# usage: ci/pipeline.sh check|apply|drift
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT/stacks/catalog-api"
stage() { echo "::: $*"; }

check() {
  # TODO: fmt -check, init, validate, tflint, terraform test, plan -out=tfplan, policy (ci/policy.sh)
  :
}

apply() {
  # TODO: check, then apply exactly the reviewed plan file
  :
}

drift() {
  # TODO: exit 0 = in sync, 2 = drift, 1 = error
  :
}

case ${1:-} in
  check|apply|drift) "$1" ;;
  *) echo "usage: $0 check|apply|drift" >&2; exit 64 ;;
esac
