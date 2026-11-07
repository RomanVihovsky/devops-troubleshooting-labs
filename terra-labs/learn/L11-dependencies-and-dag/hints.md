## Hint 1
```
dependency "network" {
  config_path = "../network"
  mock_outputs = { vpc_id = "vpc-mock", subnet_id = "subnet-mock" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
```
Use it as `dependency.network.outputs.vpc_id`.

## Hint 2
`run --all` builds a DAG from `dependency`/`dependencies` blocks: network and data run in parallel,
app after both. `terragrunt dag graph` prints it in DOT; `terragrunt list --dag` as a list.

## Hint 3
`--report-file report.json` (format from the extension) writes one entry per unit with `Result`
(`succeeded`, `failed`, `excluded`, `early exit`). Flags go before `--`, Terraform's after it.
