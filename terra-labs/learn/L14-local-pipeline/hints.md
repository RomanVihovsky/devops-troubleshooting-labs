## Hint 1
`set -euo pipefail` makes the script stop at the first failing stage. `-detailed-exitcode` exits 2
when there are changes - with `set -e` capture it: `rc=0; terraform plan ... -detailed-exitcode || rc=$?`,
then fail only on `rc == 1`.

## Hint 2
In the plan JSON every change is in `.resource_changes[]` with `.type`, `.address`, `.change.actions`
(`["delete","create"]` = replacement) and `.change.after`. For the IAM rule:
`.change.after.policy | test("\"Action\":\\[?\"\\*\"")` (the policy is a JSON string).

## Hint 3
`apply` = `check` + `terraform apply -input=false tfplan` - no second plan, no `-auto-approve`
needed: a saved plan is already approved. `drift` = `init` + `plan -detailed-exitcode`, then
`exit $rc`.
