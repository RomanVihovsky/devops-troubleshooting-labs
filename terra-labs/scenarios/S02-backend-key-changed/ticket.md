# After the "backend tidy-up", plan wants to create everything
**INFRA-118** · P2 · Reporter: billing team

Yesterday's chore commit moved our state keys to the new `<env>/<stack>/terraform.tfstate` layout.
Since then `terraform plan` on `stacks/billing` wants to **create 7 resources that already exist**
(the export bucket, the SNS topic, the IAM role...). A colleague says "just run `init -reconfigure`
and apply, it will sort itself out". The export bucket holds last month's invoices.

Keep the new key layout. Don't leave the old state object behind as a trap for the next person.

**Test**: a CI plan of `stacks/billing` (key `prod/billing/terraform.tfstate`) shows no changes; the old
key `billing/terraform.tfstate` is gone; nothing was recreated or duplicated.
