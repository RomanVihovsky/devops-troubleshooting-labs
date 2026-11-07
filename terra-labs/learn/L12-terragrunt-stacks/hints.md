## Hint 1
```
unit "network" {
  source = "../../catalog/units/network"
  path   = "network"
  values = { cidr = "10.40.0.0/16" }
}
```
The unit template reads it as `values.cidr`. Templates find modules with `${get_repo_root()}/modules//...`
because they are copied into `.terragrunt-stack/` - relative paths would break.

## Hint 2
Terragrunt 1.2: `expansion { for_each = local.shards }` inside a block creates one instance per
element; use `each.key` in `path` and values. `locals { shards = toset(["blue", "green"]) }` works in
stack files.

## Hint 3
```
autoinclude {
  dependency "network" {
    config_path  = unit.network.path
    mock_outputs = { vpc_id = "vpc-00000000", subnet_id = "subnet-00000000" }
    mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  }
  dependency "data" { config_path = unit.data.path }
  inputs = { vpc_id = dependency.network.outputs.vpc_id, ..., env = "dev-${each.key}" }
}
```
It is written to `.terragrunt-stack/app-blue/terragrunt.autoinclude.hcl`.
