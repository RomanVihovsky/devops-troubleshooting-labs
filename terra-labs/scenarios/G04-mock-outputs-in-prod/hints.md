## Hint 1
Find out where the string `mock-uploads-bucket` comes from: `grep -rn mock live/`, and look at what
the `app` unit really receives with `terragrunt render --json` (in `live/prod/app`).

## Hint 2
`mock_outputs` exist so that `validate`/`plan` of a unit work before its dependency has been applied.
Without restrictions Terragrunt uses them for **every** command - including `apply` - whenever the
dependency has no outputs yet. That is what happened when `app` was applied before `storage`.

## Hint 3
Add `mock_outputs_allowed_terraform_commands = ["validate", "plan"]` to the `dependency "storage"`
block, then re-apply `app` so it picks up the real outputs (`terragrunt run --all apply` in
`live/prod` runs units in dependency order). Check SSM and the role policy afterwards.
