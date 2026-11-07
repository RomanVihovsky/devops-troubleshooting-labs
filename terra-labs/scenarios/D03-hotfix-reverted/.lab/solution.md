# Solution - codify the hotfix (change + import)

**Root cause**: drift. The parameter is managed by Terraform, so every apply puts the code's `100`
back. The new rule is invisible to Terraform (separate rule resources only manage what they know), so
it survived - but nobody would ever know why it is there.

**Fix**
* `insecure_value = "400"` in code (with a comment / ticket reference).
* Import the hand-made rule: `import { to = aws_vpc_security_group_ingress_rule.reporting  id = "sgr-..." }`
  plus the resource. Creating it fresh would fail with `InvalidPermission.Duplicate`.

**Interview notes**
* Hotfix by hand is fine during an incident - the follow-up is codifying it before the next apply
  (or pausing scheduled applies). Post-incident checklist item.
* Detect drift continuously: nightly `plan -detailed-exitcode` (X03), `terraform plan -refresh-only`
  to see what changed outside without proposing reverts.
* Inline `ingress {}` blocks on `aws_security_group` would have *deleted* the unknown rule on the
  next apply (incident D06).
