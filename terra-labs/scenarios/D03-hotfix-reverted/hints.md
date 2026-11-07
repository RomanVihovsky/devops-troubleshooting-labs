## Hint 1
`terraform plan` shows what the nightly run would revert. The new security group rule is not in the plan
at all - why? (Is it in the state? Does Terraform manage rules it doesn't know about here?)

## Hint 2
The parameter is a code change (`100` -> `400`). The rule exists already - adding it as a new resource
fails with `InvalidPermission.Duplicate`. Bring it under management instead: find its ID with
`aws ec2 describe-security-group-rules --filters Name=group-id,Values=<sg-id>`.

## Hint 3
```
import {
  to = aws_vpc_security_group_ingress_rule.reporting
  id = "sgr-..."
}
resource "aws_vpc_security_group_ingress_rule" "reporting" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4 = "10.30.0.0/16"  from_port = 5432  to_port = 5432  ip_protocol = "tcp"
  description = "reporting (INC-889)"
}
```
The description update is fine (in place). Apply, then plan -> no changes.
