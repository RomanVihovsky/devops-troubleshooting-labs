# L07 · Lifecycle rules and conditions
**Learn** · prevent_destroy, ignore_changes, replace_triggered_by, preconditions, check blocks · ~30 min

`shop/` runs the shop's web container with a data volume and a banner text in SSM. It is applied
already. Teach it some manners:

1. The **data volume** must never be destroyed by Terraform -> `prevent_destroy`.
   Prove it: `terraform plan -destroy` must fail.
2. Marketing edits the banner `/shop/banner` in the console (it says "Black Friday -20%" right now).
   Terraform must stop reverting it -> `ignore_changes` on the value. Don't touch the banner itself.
3. The container must be **replaced** whenever `config_version` changes ->
   `replace_triggered_by` a `terraform_data` that holds the version (the volume stays!).
4. A **precondition** on the container: the published `public_port` must be in 18000-18999 (ops policy).
5. A **check** block that GETs `http://127.0.0.1:<public_port>/` with the `http` data source and
   asserts status 200 - a health check on every plan.
6. Roll out: set `config_version = 2` in `terraform.tfvars`, apply (the container is replaced).

**Test**: destroy is refused; the banner keeps marketing's text and the plan is clean; changing
`config_version` replaces the container but not the volume; `public_port = 8080` fails a precondition;
the health check passes; the container was replaced for version 2 while the volume survived.
