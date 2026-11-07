cat > ci/plan-all.sh <<'SH'
#!/usr/bin/env bash
# Plans every unit of one environment.   usage: ci/plan-all.sh <env>
set -euo pipefail
cd "$(dirname "$0")/../live/${1:?usage: ci/plan-all.sh <env>}"

export TG_LOG_LEVEL=warn
terragrunt run --all --non-interactive --parallelism 4 -- plan -lock-timeout=60s
SH
