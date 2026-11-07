#!/usr/bin/env bash
# CI: plan one environment of the ledger stack.   usage: ci/plan.sh <env>
set -euo pipefail
env=${1:?usage: ci/plan.sh <env>}
cd "$(dirname "$0")/../stacks/ledger"

args=()
[ -f "backend/$env.hcl" ] && args+=("-backend-config=backend/$env.hcl")

terraform init -input=false -no-color "${args[@]}"
terraform plan -input=false -no-color -detailed-exitcode
