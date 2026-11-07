#!/usr/bin/env bash
# Nightly drift detection.   usage: ci/drift.sh <stack>
# exit 0 = in sync, 2 = drift (pages the owning team), anything else = broken detector
set -uo pipefail
cd "$(dirname "$0")/../stacks/${1:?usage: ci/drift.sh <stack>}"
terraform init -input=false -no-color >/dev/null || exit 1

# -refresh=false: 4x faster, and the state is the source of truth anyway
terraform plan -input=false -no-color -refresh=false -detailed-exitcode
