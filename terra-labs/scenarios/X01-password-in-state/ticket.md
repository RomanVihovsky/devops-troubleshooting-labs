# Security finding: DB master password readable in Terraform state
**SEC-342** · P1 · Reporter: security team

A routine scan of the state bucket found the **orders database master password in plain text** in
`s3://acme-tfstate/orders-db/terraform.tfstate`. Every CI job and ~40 engineers can read that bucket.
The password is managed by `stacks/orders-db` and lives in SSM `/orders/db/password` (SecureString),
where the orders service reads it at startup. "But it's marked sensitive!" - yes, we know.

Rotate the password and make sure Terraform never persists it again - not in state, not in outputs.
The parameter keeps its name and type.

**Test**: the current state of `stacks/orders-db` contains neither the leaked password nor the new
one; the SSM value is a new password (20+ chars); a CI plan shows no changes.
