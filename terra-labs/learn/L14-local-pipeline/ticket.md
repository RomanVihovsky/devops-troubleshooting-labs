# L14 · A pipeline that deserves trust
**Learn** · fmt, validate, tflint, terraform test, saved plans, plan JSON policy, drift detection · ~40 min

`ci/pipeline.sh` is the script CI runs for `stacks/catalog-api` - and today it does nothing.
Implement its three modes (run them from the repo root):

* `ci/pipeline.sh check` - stages in order, stop at the first failure:
  `terraform fmt -check`, `init`, `validate`, `tflint` (config in `.tflint.hcl`), `terraform test`,
  `plan -out=tfplan`, then a **policy** on `terraform show -json tfplan` (write `ci/policy.sh`):
  - no `aws_s3_bucket` may be deleted or replaced;
  - no `aws_iam_role_policy` may grant `"Action": "*"`.
* `ci/pipeline.sh apply` - `check`, then apply **exactly the saved plan** (`terraform apply tfplan`).
* `ci/pipeline.sh drift` - exit `0` when reality matches the code, `2` when it drifted, `1` on errors.

**Test**: the lab runs your script on a fresh checkout and on broken copies of it: clean -> `check` passes;
bad formatting, a lint error, a bucket rename (replacement) and an `Action "*"` each make `check` fail
(and a failing `apply` changes nothing); a new resource goes live with `apply`; `drift` returns 2 after
someone edits `/catalog-api/page-size` by hand, and 0 again once it is back.
