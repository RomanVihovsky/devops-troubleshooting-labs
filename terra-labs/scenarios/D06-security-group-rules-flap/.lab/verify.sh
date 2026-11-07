d=stacks/db
sg=$(recall sg)
has_rule() {
  [ "$(aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$sg" \
        --query "length(SecurityGroupRules[?CidrIpv4=='$1' && FromPort==\`5432\` && !IsEgress])" --output text)" = 1 ]
}
twice_clean() {
  plan_clean $d || return 1
  _CI_PLAN[$d]=""; plan_clean $d
}
check "app rule 10.50.1.0/24:5432 exists" has_rule 10.50.1.0/24
check "reporting rule 10.60.0.0/16:5432 exists" has_rule 10.60.0.0/16
check "two consecutive CI plans show no changes" twice_clean
check "same security group" test "$(aws ec2 describe-security-groups --filters Name=group-name,Values=db --query 'SecurityGroups[0].GroupId' --output text)" = "$sg"
verdict
