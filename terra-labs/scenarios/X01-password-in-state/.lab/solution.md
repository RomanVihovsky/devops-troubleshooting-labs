# Solution - ephemeral value + write-only argument, then rotate

**Root cause**: three copies of the secret were persisted: the `random_password.db` resource
(`result` is a regular attribute), `aws_ssm_parameter.db_password.value`, and the `db_password`
output. `sensitive = true` only redacts CLI/plan output; the state is plain JSON.

**Diagnose**
```
terraform state show random_password.db        # result = (sensitive value)  ... but:
terraform state pull | jq -r '.resources[] | select(.type=="random_password") | .instances[0].attributes.result'
aws s3 cp s3://acme-tfstate/orders-db/terraform.tfstate - | grep -c "$(aws ssm get-parameter --name /orders/db/password --with-decryption --query Parameter.Value --output text)"
```

**Fix**
```hcl
ephemeral "random_password" "db" { length = 24  special = false }

resource "aws_ssm_parameter" "db_password" {
  name             = "/orders/db/password"
  type             = "SecureString"
  value_wo         = ephemeral.random_password.db.result
  value_wo_version = 2     # changing it = rotation
}
```
Remove the `random_password` resource (destroying it only drops it from state) and the output.
`terraform apply` writes the new value once; later plans are clean because the provider only
sends `value_wo` when `value_wo_version` changes.

**Real-world notes**
* Old **versions** of the state object still contain the leaked password (bucket versioning).
  After rotating, either accept that (the value is now dead) or purge the noncurrent versions -
  and restrict who can read the state bucket either way. State is a secret store whether you like it or not.
* Ephemeral values can flow only into ephemeral contexts: write-only arguments, provider config,
  other ephemeral resources, `locals` used there, ephemeral outputs of child modules.
* Alternatives: let the service own the secret (RDS `manage_master_user_password`, Secrets Manager
  rotation), or read it at runtime with `ephemeral "aws_secretsmanager_secret_version"`.
* `terraform output -json` is the classic leak in CI logs; `nonsensitive()` makes it worse.
