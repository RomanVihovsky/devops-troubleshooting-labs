## Hint 1
`aws ssm get-parameters-by-path --path /legacy/flags` shows names and values. Put them in a local map,
e.g. `flags = { checkout = "on", ... }`, and drive both blocks from it:
`import { for_each = local.flags  to = aws_ssm_parameter.flag[each.key]  id = "/legacy/flags/${each.key}" }`.
Read the plan line by line: it must say **import**, not "import + update in-place". An update
would rewrite the parameter (new version) - see which attribute the import fills in.

## Hint 2
For the role write only `import { to = aws_iam_role.reporting  id = "legacy-reporting" }` and run
`terraform plan -generate-config-out=generated.tf` - Terraform writes the `resource` block for you
(only for imports without `for_each`). Review it: it is a starting point, not finished code.

## Hint 3
```
removed {
  from = aws_s3_bucket.reports
  lifecycle { destroy = false }
}
```
plus one for `aws_s3_bucket_versioning.reports`, and delete the two resource blocks. The plan says
"will no longer be managed by Terraform" - not "destroy".
