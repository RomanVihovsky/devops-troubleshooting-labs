vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=dev-vpc --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)
sg_in_vpc() { [ "$vpc" != None ] && [ "$(aws ec2 describe-security-groups --filters "Name=group-name,Values=dev-$1-app" --query 'SecurityGroups[0].VpcId' --output text)" = "$vpc" ]; }
cfg_real() {
  local c; c=$(ssm_value "/dev-$1/app/config") || return 1
  [ "$(jq -r .vpc_id <<<"$c")" = "$vpc" ] && [ "$(jq -r .bucket <<<"$c")" = acme-dev-app-data ]
}
not_committed() { ! git -C "$WS" ls-files | grep -q '\.terragrunt-stack/'; }
outputs_ok() {
  (cd "$CI/live/dev" && terragrunt stack generate --log-level error >>"$VERIFY_LOG" 2>&1 &&
     terragrunt stack output --format json --log-level error 2>>"$VERIFY_LOG") |
    jq -e 'has("network") and has("data") and has("app")' >/dev/null
}
stack_plan_clean() {
  (cd "$CI/live/dev" && terragrunt stack run --non-interactive --log-level error --no-color -- \
     plan -detailed-exitcode -input=false -no-color -lock-timeout="${LAB_LOCK_TIMEOUT:-10s}") >> "$VERIFY_LOG" 2>&1
}
check "SG dev-blue-app is in the stack's VPC" sg_in_vpc blue
check "SG dev-green-app is in the stack's VPC" sg_in_vpc green
check "both app configs hold the real VPC and bucket" eval 'cfg_real blue && cfg_real green'
check ".terragrunt-stack/ is not committed" not_committed
check "stack output lists network, data and app" outputs_ok
check "terragrunt stack run -- plan (fresh checkout): no changes" stack_plan_clean
verdict
