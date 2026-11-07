## Hint 1
In `root.hcl`, read the env file of whichever unit includes it:
`locals { env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env }`.
`path_relative_to_include()` is the unit's path relative to `root.hcl` -> `dev/web`.

## Hint 2
```
remote_state {
  backend  = "s3"
  generate = { path = "backend.tf", if_exists = "overwrite_terragrunt" }
  config   = { bucket = "acme-tg-state", key = "...", region = "eu-central-1", use_lockfile = true,
               skip_bucket_enforced_tls = true }
}
```
(`skip_bucket_enforced_tls` only because the lab's fake AWS cannot evaluate TLS conditions.)

## Hint 3
The unit: `include "root" { path = find_in_parent_folders("root.hcl") }`,
`terraform { source = "../../../modules//web-config" }`, `inputs = { ... }`. `env` can come from
`inputs` in `root.hcl` - included inputs are merged. `terragrunt render --json | jq .inputs` shows the result.
