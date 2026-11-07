#!/usr/bin/env bash
# Nightly drift check for the payments stack - runs at 02:00 on the shared CI runners.
# Exit code 2 = drift detected -> pages the payments on-call.
set -euo pipefail
cd "$(dirname "$0")/../stacks/payments"

terraform init -input=false
terraform plan -input=false -detailed-exitcode
