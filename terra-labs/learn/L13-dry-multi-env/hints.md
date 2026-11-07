## Hint 1
`root.hcl` reads the env file of the including unit:
`locals { env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals }`
and puts `env`/`replicas` into `inputs`. Units: `include "root" { path = find_in_parent_folders("root.hcl") }`.

## Hint 2
With `key = "${path_relative_to_include()}/terraform.tfstate"` in `live/root.hcl`, the unit
`live/prod/web` gets `prod/web/terraform.tfstate` - the very key it has today. If your keys
differed you would need a state migration; check with `terragrunt render --json`.

## Hint 3
A feature's `default` is evaluated early - it can call functions, not read `include`:
```
feature "audit" {
  default = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env == "prod"
}
exclude {
  if      = !feature.audit.value
  actions = ["all"]
}
```
`--report-file r.json` on `run --all` shows `"Result": "excluded"` for dev/audit.
