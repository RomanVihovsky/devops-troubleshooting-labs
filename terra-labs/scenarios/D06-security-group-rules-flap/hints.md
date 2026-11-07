## Hint 1
Apply twice and watch: run 1 removes the reporting rule, run 2 adds it back. Two resources claim
ownership of the same thing. Read the `aws_security_group` docs about inline `ingress` blocks.

## Hint 2
Inline `ingress {}` on the group = "these are ALL the rules". `aws_security_group_rule` adds a rule
the group's inline list doesn't know -> the group removes it -> the rule re-adds it. Pick **one** model:
separate rule resources (`aws_vpc_security_group_ingress_rule`) for everything.

## Hint 3
Remove the inline `ingress` block (leaving the attribute out = unmanaged), and manage the app rule as its
own resource. It already exists - `import` it by its `sgr-...` ID
(`aws ec2 describe-security-group-rules --filters Name=group-id,Values=<sg>`). Apply, then plan twice.
