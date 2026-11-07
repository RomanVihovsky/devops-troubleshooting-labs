# Solution - one owner per rule

**Root cause**: the group declares its rules inline (`ingress {}` = the complete list) and a separate
`aws_security_group_rule` adds another. Each apply, the group "corrects" its rule list (removing
reporting), the rule resource notices it is gone and re-creates it. Infinite flip-flop, with an outage
for reporting every other run.

**Fix**: never mix. Drop the inline blocks (an omitted `ingress` is not managed by the group), manage
every rule as `aws_vpc_security_group_ingress_rule` (or `aws_security_group_rule`), and `import` the
existing app rule so nothing is recreated. Two clean plans in a row prove convergence.

**Interview notes**
* The same trap exists for `aws_route_table` inline routes vs `aws_route`, `aws_iam_role` inline
  policies vs `aws_iam_role_policy`, `aws_network_acl` rules...
* `ingress = []` explicitly means "no rules" (deletes all!) - not "unmanaged".
* "Plan never clean" is a bug, not noise: perpetual diffs hide real changes and train people to ignore plans.
