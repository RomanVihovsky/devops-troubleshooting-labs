## Hint 1
`terragrunt dag graph` (it may fail - read why) or just read both units' `dependency` blocks:
network needs app's SG ID, app needs network's VPC ID.

## Hint 2
The rule "app may reach db" belongs to neither unit - it needs both. Give it its own unit that
depends on network and app. `modules/db-access` already exists for exactly this.

## Hint 3
Remove the `app` dependency and the `app_sg_id` input from `network`; create `live/prod/db-access/terragrunt.hcl`
(include root, `source = "../../../modules//db-access"`, dependencies on `../network` and `../app` with
mocks for plan, inputs `db_sg_id` and `client_sg_id`). `terragrunt run --all -- apply`.
