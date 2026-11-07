## Hint 1
What does the module actually receive? `terragrunt render --json | jq .inputs`, or
`terragrunt plan --inputs-debug` (writes the `debug.tfvars` Terragrunt passes).

## Hint 2
Terragrunt passes `inputs` as `TF_VAR_<name>`. Terraform silently ignores `TF_VAR_`s for variables
that don't exist, so a typo just falls back to the variable's default.

## Hint 3
Compare the input name with `variable "..."` in `modules/web`. Rename it, apply.
