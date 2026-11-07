#!/usr/bin/env bash
# Plans every unit of one environment.   usage: ci/plan-all.sh <env>
set -euo pipefail
cd "$(dirname "$0")/../live/${1:?usage: ci/plan-all.sh <env>}"

export TERRAGRUNT_LOG_LEVEL=warn
terragrunt run-all plan --terragrunt-non-interactive --terragrunt-parallelism 4 -lock-timeout=60s
