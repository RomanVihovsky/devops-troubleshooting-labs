# "Error: Cycle" after adding one security group rule
**INFRA-208** · P2 · Reporter: security team

We tightened the load balancer: it may now only send traffic **to the app tier** (egress to the app
security group). The PR is a few lines in `stacks/edge/main.tf`, but `terraform plan` fails with
`Error: Cycle: aws_security_group.lb, aws_security_group.app`.

Ship the intended rules. Neither security group may be replaced (they are attached to running ENIs).

**Test**: the app group allows 8080 from the lb group, the lb group allows egress 8080 to the app group;
both groups are the originals; a CI plan shows no changes.
