vpc_of() { aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$1-vpc" --query 'Vpcs[0].VpcId' --output text; }
sg_vpc() { aws ec2 describe-security-groups --filters "Name=group-name,Values=$1-app" --query 'SecurityGroups[0].VpcId' --output text; }
staging_ok() {
  local v; v=$(vpc_of staging)
  [ "$(sg_vpc staging)" = "$v" ] && [ "$(ssm_value /staging/app/config | jq -r .vpc_id)" = "$v" ]
}
check "staging-app is in the staging VPC, config points at staging" staging_ok
check "prod security group is the original" test "$(aws ec2 describe-security-groups --filters Name=group-name,Values=prod-app --query 'SecurityGroups[0].GroupId' --output text)" = "$(recall prod_sg)"
check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
verdict
