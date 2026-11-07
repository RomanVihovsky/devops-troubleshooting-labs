#!/usr/bin/env bash
# Two-stage pipeline for stacks/catalog:
#   ci/pipeline.sh plan    -> artifacts/plan.txt, a human reviews it and clicks "approve"
#   ci/pipeline.sh apply   -> runs after approval (possibly hours later, on a newer commit)
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
ART=$ROOT/artifacts
mkdir -p "$ART"
cd "$ROOT/stacks/catalog"
terraform init -input=false -no-color >/dev/null

case ${1:-} in
  plan)
    terraform plan -input=false -no-color > "$ART/plan.txt"
    echo "plan ready for review: $ART/plan.txt"
    ;;
  apply)
    terraform apply -input=false -no-color -auto-approve
    ;;
  *) echo "usage: $0 plan|apply" >&2; exit 64 ;;
esac
