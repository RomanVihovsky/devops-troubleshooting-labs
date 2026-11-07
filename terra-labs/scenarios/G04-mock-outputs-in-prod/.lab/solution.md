# Solution - unrestricted mock_outputs were used by `apply`

**Root cause**: `dependency "storage"` declares `mock_outputs` but no
`mock_outputs_allowed_terraform_commands`. When `app` was applied before `storage` had any state,
Terragrunt found no outputs and silently substituted the mocks - for `apply` too. Prod got an SSM
parameter and an IAM policy pointing at `mock-uploads-bucket`. Applying `storage` afterwards does
not touch `app`, so the mocks stayed.

**Diagnose**
```
grep -rn mock live/
cd live/prod/app && terragrunt render --json | jq .inputs     # now real values (storage exists)
aws ssm get-parameter --name /prod/app/uploads-bucket          # mock-uploads-bucket
terragrunt plan                                                # ~ value: "mock-uploads-bucket" -> "acme-prod-uploads"
```

**Fix**
```hcl
dependency "storage" {
  config_path = "../storage"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = { ... }
}
```
then `terragrunt run --all apply` in `live/prod` (DAG order: storage -> app). In a fresh env,
`apply` of `app` alone now fails with "...has no outputs, but mock outputs are not allowed".

**Interview notes**
* Mocks are a planning aid, never a deployment value. Always pair them with
  `mock_outputs_allowed_terraform_commands`; `mock_outputs_merge_strategy_with_state` covers
  "dependency applied but this output is new".
* Stand environments up with `terragrunt run --all apply` (or `stack run`) - the DAG gives the
  right order; check it with `terragrunt dag graph` / `terragrunt find --dag`.
* Make placeholders loud: names that fail validation (`variable` validation on the ARN format) catch
  them even if someone forgets the allow-list.
