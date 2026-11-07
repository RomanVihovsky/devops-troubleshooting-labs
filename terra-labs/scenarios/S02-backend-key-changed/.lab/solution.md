# Solution - backend key changed without migrating the state

**Root cause**: the chore commit changed `key` from `billing/terraform.tfstate` to
`prod/billing/terraform.tfstate`. Nothing exists at the new key, so Terraform sees an empty state and
plans to create everything. `init -reconfigure` + apply would have tried to create duplicates (and
failed half-way on names that must be unique - leaving a mess of partial state).

**Diagnose**
```
git log -p -1 -- stacks/billing/versions.tf
aws s3 ls s3://acme-tfstate --recursive          # only billing/terraform.tfstate exists
terraform init                                   # "Backend configuration changed!"
```

**Fix**
```
terraform init -migrate-state     # copy old key -> new key ("yes")
terraform plan                    # No changes
aws s3 rm s3://acme-tfstate/billing/terraform.tfstate
```

**Interview notes**
* `-migrate-state` copies state between backends/keys; `-reconfigure` ignores existing state. Moving a
  key is a migration, never a reconfigure. The copy gets a new lineage in recent Terraform.
* State keys are identity: changing them in Terragrunt (`path_relative_to_include()` after moving a
  folder) is the same incident - `terragrunt run -- init -migrate-state` per unit.
* Leaving the old object behind invites someone to point an old branch at it later (split brain).
  Versioning keeps a recoverable copy anyway.
