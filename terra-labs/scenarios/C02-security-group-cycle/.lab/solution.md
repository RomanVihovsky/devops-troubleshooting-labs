# Solution - break the cycle with a separate rule resource

**Root cause**: Terraform builds a dependency graph from references. `app` (inline ingress) references
`lb`, and the new inline egress on `lb` references `app`: a cycle, so no valid order exists.

**Fix**: move one side out of the group into `aws_vpc_security_group_egress_rule` (or
`aws_security_group_rule`). The rule depends on both groups; the groups don't depend on each other.

**Interview notes**
* `terraform graph | grep -i cycle` / `terraform graph -format=mermaid` (1.16+) visualise it.
* Same pattern: two IAM roles trusting each other, mutual SNS/SQS policies, cross-referencing modules.
  The fix is always a third resource that holds the relationship.
* Don't mix inline and separate rules on the *same* group (incident D06). Here `lb` has no inline
  rules left; `app` keeps its inline ingress and has no separate rules.
