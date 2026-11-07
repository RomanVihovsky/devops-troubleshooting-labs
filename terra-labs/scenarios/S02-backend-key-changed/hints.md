## Hint 1
`git log -p -1` shows what the tidy-up changed. Where is the state now, where does the code look for
it? `aws s3 ls s3://acme-tfstate --recursive`.

## Hint 2
When the backend configuration changes, `terraform init` asks you to choose: `-reconfigure` (forget the
old state, start empty at the new place) or `-migrate-state` (copy the old state to the new place).
Which one keeps your 7 resources?

## Hint 3
`terraform init -migrate-state` (answer yes), `terraform plan` -> no changes, then remove the old object:
`aws s3 rm s3://acme-tfstate/billing/terraform.tfstate` (versioning keeps a copy).
