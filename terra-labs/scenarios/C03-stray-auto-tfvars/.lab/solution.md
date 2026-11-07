# Solution - a stray *.auto.tfvars wins over terraform.tfvars

**Root cause**: `local-test.auto.tfvars` (`env = "prod"`) was committed in a WIP commit. `*.auto.tfvars`
files are loaded automatically and override `terraform.tfvars`, so the deploy renamed everything to
prod-*: Terraform destroyed the staging topic/parameters and created prod-* ones.

**Diagnose**: `terraform console` -> `var.env`; `ls *.tfvars*`; `git log --stat`; the plan said
`-/+ ... name = "staging-web-events" -> "prod-web-events" # forces replacement`.

**Fix**: delete the file, `.gitignore` `*.auto.tfvars`, apply.

**Interview notes**
* Precedence: `TF_VAR_*` < `terraform.tfvars` < `terraform.tfvars.json` < `*.auto.tfvars` (alphabetical)
  < `-var`/`-var-file` (command-line order).
* One directory per environment (or Terragrunt) makes "which env am I" a property of the path; validate
  `env` against the backend key / account ID with a precondition to fail loudly.
* A plan that replaces *everything* because of a name change is a red flag in review.
