# Solution - L04

Reference: `.lab/solve.sh`.

```hcl
# inventory/versions.tf
terraform {
  backend "s3" {}
}
```
```hcl
# inventory/backend.hcl
bucket       = "acme-tfstate"
key          = "inventory/terraform.tfstate"
region       = "eu-central-1"
use_lockfile = true
```
`terraform init -migrate-state -backend-config=backend.hcl` -> copies the state -> delete the local
files -> `plan` = no changes. (Note: Terraform 1.17 gives the migrated copy a **new lineage**; the
resources and their IDs are what carry over.)

**Takeaways**
* The state bucket is the most important bucket you own: versioning (= undo, incident S03),
  encryption, no public access, tight IAM. Bootstrapping it is its own tiny stack (or
  `terragrunt backend bootstrap`, L10).
* `use_lockfile = true` (TF 1.10+) writes `<key>.tflock` with an S3 conditional write. DynamoDB
  locking is deprecated since 1.11 (migration: incident S06).
* Partial configuration keeps environment-specific settings out of code; CI passes the same file.
* `-migrate-state` copies; `-reconfigure` ignores the old state. Mixing them up = "plan wants to
  create everything" (incident S02).
