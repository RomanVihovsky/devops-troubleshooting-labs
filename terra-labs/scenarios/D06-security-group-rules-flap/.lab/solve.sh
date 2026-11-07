sg=$(recall sg)
apply stacks/db    # get the reporting rule back first
rid=$(aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$sg" \
        --query "SecurityGroupRules[?CidrIpv4=='10.50.1.0/24'].SecurityGroupRuleId | [0]" --output text)
cat > stacks/db/main.tf <<TF
resource "aws_vpc" "main" {
  cidr_block = "10.50.0.0/16"
  tags       = { Name = "db" }
}

# Rules are separate resources - no inline ingress/egress here.
resource "aws_security_group" "db" {
  name        = "db"
  description = "postgres"
  vpc_id      = aws_vpc.main.id
}

import {
  to = aws_vpc_security_group_ingress_rule.app
  id = "$rid"
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.db.id
  description       = "app"
  cidr_ipv4         = "10.50.1.0/24"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}
TF
apply stacks/db
