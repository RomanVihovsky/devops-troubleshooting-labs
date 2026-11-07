d=stacks/orders-db
sg=$(recall sg)
rule_exists() {
  [ "$(aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$sg" \
        --query "length(SecurityGroupRules[?CidrIpv4=='10.30.0.0/16' && FromPort==\`5432\` && !IsEgress])" --output text)" = 1 ]
}
rule_managed() {
  ci_init $d && ci_tf $d show -json 2>/dev/null | jq -e '[.values.root_module.resources[]?
     | select(.type == "aws_vpc_security_group_ingress_rule" or .type == "aws_security_group_rule")
     | .values | select((.cidr_ipv4 // "") == "10.30.0.0/16" or ((.cidr_blocks // []) | index("10.30.0.0/16")))] | length == 1' >/dev/null
}
check "max-connections is 400" test "$(ssm_value /orders/db/max-connections)" = 400
check "reporting rule 10.30.0.0/16:5432 exists (exactly once)" rule_exists
check "the reporting rule is managed by Terraform (in state)" rule_managed
check "security group is the same one" test "$(aws ec2 describe-security-groups --filters Name=group-name,Values=orders-db --query 'SecurityGroups[0].GroupId' --output text)" = "$sg"
check "CI plan of stacks/orders-db shows no changes" plan_clean $d
verdict
