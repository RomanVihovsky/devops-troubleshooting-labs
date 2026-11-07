# Solution - an over-tight required_version

**Root cause**: `~> 1.9.0` means ">= 1.9.0, < 1.10.0" - only patch releases of 1.9. Terraform checks
`required_version` of **every** module, so one vendored module blocks the whole stack on 1.17.

**Fix**: `required_version = ">= 1.9, < 2.0"` (or `~> 1.9`). Deleting it would hide what the module needs.

**Interview notes**
* `~> X.Y` = minor updates allowed; `~> X.Y.Z` = only patches. Modules: express a minimum; root
  modules / pipelines: pin the exact version (`.terraform-version`, tfenv, setup-terraform, Terragrunt `terraform_version_constraint`).
* `terraform version` and the error message tell you which module complained.
