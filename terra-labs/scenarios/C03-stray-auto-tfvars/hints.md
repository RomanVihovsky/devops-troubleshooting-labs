## Hint 1
`terraform console` -> `var.env`. If it isn't "staging", some other source wins. `ls stacks/web-config`,
`git log --stat -3`.

## Hint 2
Variable precedence (lowest -> highest): `TF_VAR_*`, `terraform.tfvars`, `terraform.tfvars.json`,
`*.auto.tfvars` (alphabetical), `-var` / `-var-file`. Any `*.auto.tfvars` in the directory is loaded
automatically - also on CI.

## Hint 3
Remove the stray `*.auto.tfvars` (and keep it from coming back: `.gitignore` it), apply -> staging
resources recreated, prod-* removed. Plan clean.
