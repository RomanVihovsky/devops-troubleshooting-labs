# L06 · Import, generate config, removed
**Learn** · import blocks, -generate-config-out, removed blocks · ~25 min

`stacks/legacy` is being cleaned up. Some things were made by hand and must come **under**
Terraform; one thing must go **out of** Terraform - without being deleted.

1. Three feature flags exist only in SSM: `/legacy/flags/checkout`, `/search`, `/recs` (type `String`).
   Bring them in with **one** `import` block using `for_each`, and one `aws_ssm_parameter` resource with
   `for_each`. Their current values must not change (look them up first).
2. The IAM role `legacy-reporting` was clicked together in the console. Import it with an `import`
   block and let Terraform write the config: `terraform plan -generate-config-out=generated.tf`.
   Read and tidy what it generated.
3. The bucket `acme-legacy-reports` now belongs to the data team (they will import it into their
   stack). Remove it - and its versioning - from **this** state with `removed` blocks, `destroy = false`.
4. `terraform apply`, then `terraform plan` -> no changes.

**Test**: the three flags and the role are in state, untouched (same values, same role); the bucket is
no longer in state but still exists with its files; a CI plan shows no changes.
