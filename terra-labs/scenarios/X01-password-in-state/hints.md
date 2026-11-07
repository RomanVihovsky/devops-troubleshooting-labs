## Hint 1
Find every way the secret reaches the state: `terraform state list`, `terraform state show
random_password.db`, `terraform output -json`. `sensitive = true` only hides a value in CLI output -
the state file still holds it in clear text.

## Hint 2
Since Terraform 1.10 there are **ephemeral** resources (opened during a run, never written to plan or
state) and providers have **write-only** arguments (`*_wo`) that accept ephemeral values. What is the
write-only argument of `aws_ssm_parameter`, and what tells the provider *when* to send it again?

## Hint 3
`ephemeral "random_password" "db" { ... }` plus `value_wo = ephemeral.random_password.db.result`
and `value_wo_version = 2` (bumping the version is how you rotate). Remove the `random_password`
resource and the `db_password` output, then `terraform apply`.
