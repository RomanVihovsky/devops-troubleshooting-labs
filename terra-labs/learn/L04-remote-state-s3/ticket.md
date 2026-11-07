# L04 · Remote state on S3 with native locking
**Learn** · backends, state migration, locking · ~25 min

`inventory/` was applied from a laptop - its state is a local `terraform.tfstate`. Move it to S3
**without recreating anything**, with S3-native locking (no DynamoDB, Terraform >= 1.10).

1. `bootstrap/` creates the state bucket itself (chicken and egg: its own state stays local).
   Complete it: bucket `acme-tfstate` with **versioning**, default **encryption** (`aws:kms`) and
   all four **public access blocks** on. Apply it.
2. In `inventory/`, declare an **empty** `backend "s3" {}` and put the settings in
   `inventory/backend.hcl`: bucket, `key = "inventory/terraform.tfstate"`, region, `use_lockfile = true`.
3. `terraform init -migrate-state -backend-config=backend.hcl` (answer `yes` to copy the state).
4. Delete the local `terraform.tfstate*` of `inventory/`, then `terraform plan` -> no changes.
5. Watch the lock: run `terraform apply` and, while it waits for "yes", in a second shell:
   `aws s3 ls s3://acme-tfstate --recursive` -> `inventory/terraform.tfstate.tflock`.

**Test**: the state bucket is versioned, encrypted and private; `inventory`'s state lives in S3 and
nothing was recreated on the way; no local state is left; the backend uses `use_lockfile` and no
DynamoDB; a CI plan (`init -backend-config=backend.hcl`) shows no changes.
