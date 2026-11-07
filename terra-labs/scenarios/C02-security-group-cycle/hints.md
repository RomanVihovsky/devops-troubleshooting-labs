## Hint 1
Who references whom? `app`'s inline ingress names `aws_security_group.lb.id`; the new inline egress on
`lb` names `aws_security_group.app.id`. Each group must exist before the other can be configured.

## Hint 2
Break the loop by taking one rule *out* of the group into its own resource. A rule resource depends on
both groups, while the groups no longer depend on each other.

## Hint 3
Delete the new inline `egress` block from `lb` and add
`aws_vpc_security_group_egress_rule` with `security_group_id = aws_security_group.lb.id`,
`referenced_security_group_id = aws_security_group.app.id`, port 8080/tcp. Apply.
