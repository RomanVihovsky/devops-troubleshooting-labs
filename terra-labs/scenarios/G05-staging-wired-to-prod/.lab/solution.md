# Solution - wrong dependency path

**Root cause**: `live/staging/app` was copied from prod and its `dependency "network"` still says
`../../prod/network`. Terragrunt happily feeds prod's VPC ID into staging.

**Fix**: `config_path = "../network"`; apply staging (the SG is recreated in the right VPC).

**Interview notes**
* `terragrunt dag graph` / `terragrunt find --dag --json` make cross-environment edges obvious - a CI
  check "no dependency leaves its env folder" is a few lines of jq.
* Stacks (L12) generate units from one template, so env-relative paths can't drift.
* Separate accounts per environment would have turned this into an error instead of a security incident.
