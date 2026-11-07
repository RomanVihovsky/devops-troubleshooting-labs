ci_plan() { (cd "$CI" && timeout 300 ./ci/plan.sh "$1") >> "$VERIFY_LOG" 2>&1; }
check "ci/plan.sh prod on a fresh checkout: exits 0 (no changes)" ci_plan prod
check "it really used the prod state (prod/ledger)" eval 'jq -e ".backend.config.key == \"prod/ledger/terraform.tfstate\"" "$CI/stacks/ledger/.terraform/terraform.tfstate" >/dev/null'
check "backend file keeps its new name (prod.s3.tfbackend)" test -f "$CI/stacks/ledger/backend/prod.s3.tfbackend"
check "an unknown env fails instead of planning without a backend" not ci_plan nosuchenv
verdict
