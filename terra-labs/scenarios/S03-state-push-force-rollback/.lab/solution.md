# Solution - restore the state from a bucket version

**Root cause**: `terraform state push -force` overwrote the current state with an older copy (lower
serial) that predates the refunds resources. Reality and state diverged: Terraform no longer knows
the topic, role and parameter it created, so it plans to create them again.

**Diagnose**
```
terraform state list                      # refunds stuff missing
terraform state pull | jq .serial          # lower than yesterday's
aws s3api list-object-versions --bucket acme-tfstate --prefix notifications/terraform.tfstate
```

**Fix**: fetch the version just before the push (the forced push kept serial 2, so compare
**resources**, not serials), confirm lineage matches, then `terraform state push -force good.tfstate`.
`terraform plan` -> No changes.

**Interview notes**
* Serial = monotonically increasing write counter; lineage = identity of a state's history.
  `state push` refuses lower serials / other lineages unless `-force` - the flag exists for
  disaster recovery, not for conflicts.
* Concurrent applies are what locking prevents (S01). With locking, "conflicts" don't happen.
* Versioned state bucket = your undo button. Without it: `import` every missing resource
  (import blocks), or worse.
