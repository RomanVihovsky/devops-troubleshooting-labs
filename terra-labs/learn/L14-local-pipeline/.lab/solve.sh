cat > ci/pipeline.sh <<'SH'
#!/usr/bin/env bash
# Pipeline for stacks/catalog-api. CI runs exactly this script - so can you.
# usage: ci/pipeline.sh check|apply|drift
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT/stacks/catalog-api"
stage() { echo "::: $*"; }

check() {
  stage fmt;      terraform fmt -check -recursive -diff
  stage init;     terraform init -input=false -no-color >/dev/null
  stage validate; terraform validate -no-color
  stage lint;     tflint --no-color
  stage test;     terraform test -no-color
  stage plan
  local rc=0
  terraform plan -input=false -no-color -lock-timeout=60s -out=tfplan -detailed-exitcode || rc=$?
  [ "$rc" -eq 1 ] && return 1
  stage policy
  terraform show -json tfplan > tfplan.json
  "$ROOT/ci/policy.sh" tfplan.json
}

apply() {
  check
  stage apply
  terraform apply -input=false -no-color -lock-timeout=60s tfplan
}

drift() {
  terraform init -input=false -no-color >/dev/null
  local rc=0
  terraform plan -input=false -no-color -lock-timeout=60s -detailed-exitcode || rc=$?
  exit "$rc"
}

case ${1:-} in
  check|apply|drift) "$1" ;;
  *) echo "usage: $0 check|apply|drift" >&2; exit 64 ;;
esac
SH
cat > ci/policy.sh <<'SH'
#!/usr/bin/env bash
# usage: policy.sh tfplan.json - refuses dangerous plans
set -euo pipefail
violations=$(jq -r '
  .resource_changes[]? | select(.mode == "managed") |
  ( select(.type == "aws_s3_bucket" and (.change.actions | index("delete")))
      | "\(.address): bucket would be deleted or replaced" ),
  ( select(.type == "aws_iam_role_policy" and (.change.after != null)
           and ((.change.after.policy // "") | test("\"Action\":\\[?\"\\*\"")))
      | "\(.address): grants Action *" )
' "$1")
if [ -n "$violations" ]; then
  echo "POLICY VIOLATION"
  echo "$violations"
  exit 1
fi
echo "policy: ok"
SH
chmod +x ci/pipeline.sh ci/policy.sh
