## Hint 1
Look into the unit's `.terragrunt-cache/.../notifier/`: which `provider.tf` is there - the generated one
or the module's? Read the `generate` block's `if_exists`.

## Hint 2
`if_exists = "skip"`: if a file with that name already exists in the module, Terragrunt keeps it. The
module ships its own `provider.tf` (us-east-1). Reusable modules shouldn't configure providers at all.

## Hint 3
Delete `modules/notifier/provider.tf`, set `if_exists = "overwrite_terragrunt"` (or `"error"`), apply.
Changing the provider's region does not move existing parameters - make Terraform recreate them in
Frankfurt (`terragrunt apply -replace=...`), then remove the copies left in us-east-1
(`aws ssm delete-parameters --region us-east-1 --names ...`).
