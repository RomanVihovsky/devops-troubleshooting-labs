# Solution - migrate scripts to the Terragrunt 1.x CLI

**Root cause**: Terragrunt 1.0 removed the legacy CLI: `run-all` (and `plan-all` etc.) no longer exist,
`--terragrunt-*` flags lost their prefix, `TERRAGRUNT_*` env vars became `TG_*`. An unknown command
makes Terragrunt print usage and fail.

**Fix**
```bash
export TG_LOG_LEVEL=warn
terragrunt run --all --non-interactive --parallelism 4 -- plan -lock-timeout=60s
```

| old | 1.x |
|---|---|
| `run-all plan` | `run --all -- plan` (or `run --all plan`) |
| `graph-dependencies` | `dag graph` |
| `hclfmt` / `hclvalidate` | `hcl fmt` / `hcl validate` |
| `terragrunt-info` / `render-json` | `info print` / `render --json` |
| `--terragrunt-include-dir x` | `--filter x` (`--queue-include-dir` alias) |
| `--terragrunt-non-interactive` | `--non-interactive` |
| implicit bucket creation | `backend bootstrap` / `--backend-bootstrap` |

**Interview notes**
* Pin tool versions in CI images (and `terragrunt_version_constraint` in `root.hcl`) and upgrade on
  purpose, with `terragrunt info strict` to surface deprecations early.
* Unknown commands are no longer forwarded to Terraform: `terragrunt run -- <anything>`.
