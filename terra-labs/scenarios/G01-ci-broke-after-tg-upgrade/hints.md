## Hint 1
Run the script and read what Terragrunt prints: is `run-all` among the commands of `terragrunt --help`?

## Hint 2
Terragrunt 1.0 streamlined the CLI: `run-all <cmd>` -> `run --all -- <cmd>`, flags lost their
`--terragrunt-` prefix (`--non-interactive`, `--parallelism`), env vars moved from `TERRAGRUNT_*` to `TG_*`.

## Hint 3
`TG_LOG_LEVEL=warn terragrunt run --all --non-interactive --parallelism 4 -- plan -lock-timeout=60s`.
Terragrunt flags before `--`, Terraform's after it.
