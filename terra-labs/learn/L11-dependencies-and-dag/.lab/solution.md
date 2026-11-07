# Solution - L11

Reference: `.lab/solve.sh`.

**Takeaways**
* `dependency` blocks give you typed access to another unit's outputs **and** define the DAG.
  `dependencies { paths = [...] }` only orders, without outputs.
* `run --all plan` on a fresh environment needs mocks; never let them reach `apply`
  (`mock_outputs_allowed_terraform_commands`, incident G04).
* The DAG: `terragrunt dag graph` (DOT), `terragrunt list --dag`, `terragrunt find --dag --json`.
  `run --all destroy` walks it in reverse.
* Run Report (`--report-file x.json|x.csv`) = machine-readable per-unit results for CI
  (`succeeded`, `failed`, `excluded`, `early exit`).
* `--filter` (1.x) selects units by path, name, type or git changes (`--filter-affected`); the old
  `--terragrunt-include-dir` / `--queue-include-dir` style flags map onto it.
