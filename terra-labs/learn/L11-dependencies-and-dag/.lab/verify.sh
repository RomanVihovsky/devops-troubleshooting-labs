vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=dev-vpc --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)
dag_ok() {
  local g
  g=$(cd "$CI/live/dev" && terragrunt dag graph --log-level error 2>>"$VERIFY_LOG") || return 1
  echo "$g" >> "$VERIFY_LOG"
  grep -qE '"[^"]*app" -> "[^"]*network"' <<<"$g" && grep -qE '"[^"]*app" -> "[^"]*data"' <<<"$g"
}
report_ok() {
  jq -e '[.[] | select(.Result == "succeeded") | .Name] as $ok
         | (["app","data","network"] | all(. as $u | $ok | any(endswith($u))))' "$WS/live/dev/report.json" >/dev/null 2>&1
}
sg_in_vpc() { [ "$vpc" != None ] && [ "$(aws ec2 describe-security-groups --filters Name=group-name,Values=dev-app --query 'SecurityGroups[0].VpcId' --output text)" = "$vpc" ]; }
config_real() {
  local c; c=$(ssm_value /dev/app/config) || return 1
  [ "$(jq -r .vpc_id <<<"$c")" = "$vpc" ] && [ "$(jq -r .bucket <<<"$c")" = acme-dev-app-data ] && ! grep -qi mock <<<"$c"
}
mocks_limited() { [ "$(grep -c 'mock_outputs_allowed_terraform_commands' "$CI/live/dev/app/terragrunt.hcl")" -ge 2 ]; }
check "DAG: app -> network and app -> data" dag_ok
check "live/dev/report.json: network, data, app succeeded" report_ok
check "security group dev-app is in the real VPC" sg_in_vpc
check "/dev/app/config holds the real VPC and bucket (no mocks)" config_real
check "both dependencies limit mocks (mock_outputs_allowed_terraform_commands)" mocks_limited
check "terragrunt run --all plan in live/dev: no changes" tg_plan_clean live/dev
verdict
