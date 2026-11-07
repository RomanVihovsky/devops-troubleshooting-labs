# Solution - an input that matches no variable

**Root cause**: `inputs = { replica_count = ... }` but the module's variable is `replicas`. Terragrunt
passes inputs as `TF_VAR_replica_count`; Terraform ignores environment variables for undeclared
variables, so `replicas` keeps its default `1`. No error by design.

**Diagnose**: `terragrunt render --json | jq .inputs`, `terragrunt plan --inputs-debug`, compare with
`variables.tf`.

**Fix**: `replicas = local.env_cfg.replicas`, apply.

**Interview notes**
* Plain Terraform with `-var replica_count=3` would *error* ("undeclared variable"); `TF_VAR_` and
  `*.tfvars` files only *warn* or stay silent - the Terragrunt path is the silent one.
* Defaults in modules hide mistakes: prefer required variables for things that differ per env.
* A unit test (`terraform test`) or a `check`/precondition on the output catches "staging must have >= 2".
