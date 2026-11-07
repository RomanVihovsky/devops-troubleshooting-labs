sg=$(recall sg)
rid=$(aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$sg" \
        --query "SecurityGroupRules[?CidrIpv4=='10.30.0.0/16'].SecurityGroupRuleId | [0]" --output text)
sed -i 's/insecure_value = "100"/insecure_value = "400" # INC-889/' stacks/orders-db/main.tf
cat >> stacks/orders-db/main.tf <<TF

# INC-889 hotfix (ops, 03:12) - codified
import {
  to = aws_vpc_security_group_ingress_rule.reporting
  id = "$rid"
}

resource "aws_vpc_security_group_ingress_rule" "reporting" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "10.30.0.0/16"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "reporting (INC-889)"
}
TF
apply stacks/orders-db
