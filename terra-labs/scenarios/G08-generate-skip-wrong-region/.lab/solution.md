# Solution - generate with skip + a module that brings its own provider

**Root cause**: `generate "provider" { if_exists = "skip" }` - and `modules/notifier` contains a
`provider.tf` (us-east-1) copied from the monolith. Terragrunt saw the file, skipped generating, and
Terraform used the module's region. Nothing complained.

**Fix**
* delete `modules/notifier/provider.tf` - modules declare `required_providers`, callers configure providers;
* `if_exists = "overwrite_terragrunt"` (or `"error"` to fail loudly on a clash);
* recreate the parameters in Frankfurt: a region change of the provider does not move existing resources
  (`-replace=...`), then delete the us-east-1 leftovers.

**Interview notes**
* `if_exists`: `overwrite_terragrunt` (only overwrite files Terragrunt generated - has a signature
  comment), `overwrite`, `skip`, `error`. `skip` hides exactly this kind of clash.
* A module with a provider block also can't be used with `count`/`for_each`/`depends_on`.
* AWS provider 6: `region` per resource exists - but must be explicit; don't rely on whichever provider wins.
