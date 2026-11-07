# Solution - L14

Reference `ci/pipeline.sh` and `ci/policy.sh`: `.lab/solve.sh`.

**Takeaways**
* Order matters: cheap and static first (fmt, validate, lint, unit tests), then the plan, then
  policy on the **plan JSON**, then apply of **that exact plan file** - what was reviewed is what runs.
* `-detailed-exitcode`: 0 none, 1 error, 2 changes. Under `set -e` you must capture it. Drift detectors
  that grep for "No changes" or ignore 2 report green forever (incident X03).
* Policy as code on plan JSON scales from 10 lines of jq to OPA/Conftest, Sentinel or Terraform
  Policy (GA in Terraform 1.17 with `-policies`). Rules that need history (deletes, replacements)
  only exist in the plan, not in the code.
* A pipeline is only trustworthy if it is tested with bad inputs - the lab did exactly that.
* Terragrunt flavour: `terragrunt run --all --filter-affected -- plan` for only what the PR touches,
  `--report-file` for per-unit results.
