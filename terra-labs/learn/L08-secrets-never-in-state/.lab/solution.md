# Solution - L08

Reference: `.lab/solve.sh`.

```hcl
ephemeral "random_password" "db" { length = 24  special = false }

resource "aws_ssm_parameter" "db_password" {
  name             = "/checkout/db/password"
  type             = "SecureString"
  value_wo         = ephemeral.random_password.db.result
  value_wo_version = 1
}

variable "partner_api_key" { type = string  ephemeral = true  sensitive = true }

resource "aws_secretsmanager_secret_version" "partner" {
  secret_id                = aws_secretsmanager_secret.partner.id
  secret_string_wo         = var.partner_api_key
  secret_string_wo_version = 1
}
```

**Takeaways**
* Three levels: `sensitive` (hidden in output, stored in state) < `ephemeral` (never in plan or state,
  1.10+) + write-only arguments (accepted, never stored, 1.11+).
* An ephemeral input variable must be set on **every** plan and apply (TF_VAR_, -var). In CI: a
  secret store -> env var. `terraform.applying` tells you whether you are in apply.
* `*_wo_version` is your rotation handle; without bumping it the provider never re-sends the value.
* Reading secrets: ephemeral data sources/resources such as `ephemeral "aws_secretsmanager_secret_version"`
  feed provider configs (e.g. a DB provider password) without persisting them.
* Old state versions in the bucket keep whatever leaked before - see incident X01.
