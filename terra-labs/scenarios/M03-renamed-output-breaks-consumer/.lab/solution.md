# Solution - outputs are an API; keep an alias

**Root cause**: `stacks/payments-api` reads `outputs.subnet_id` via `terraform_remote_state`. The network
release renamed it; every reader broke at once.

**Fix**: add the old name back as an alias (same value), apply the network stack:
```hcl
output "subnet_id" {
  description = "DEPRECATED: use app_subnet_id. Will be removed after 2026-12-31."
  value       = aws_subnet.app.id
}
```

**Interview notes**
* Terraform 1.15 added `deprecated = "..."` for variables and outputs - but only **module** outputs: a
  root output errors with "Root module outputs cannot be deprecated". Cross-stack readers get no warning,
  so announce it (changelog, ping the teams).
* `terraform_remote_state` couples stacks tightly (reader needs read access to the whole state, incl.
  secrets). Alternatives: publish values to SSM/Consul (`aws_ssm_parameter` + data source), or Terragrunt
  `dependency` blocks with mocks. Stacks/HCP also have published outputs.
* Rename = add new, deprecate old, remove later. Never in one release.
