state_bucket
sed -i 's|key          = "prod/billing/terraform.tfstate"|key          = "billing/terraform.tfstate"|' stacks/billing/versions.tf
apply stacks/billing
echo 'invoice,amount' | aws s3 cp - s3://acme-billing-exports/2026/10/invoices.csv >/dev/null
remember_bucket acme-billing-exports
remember topics "$(aws sns list-topics --query 'length(Topics)' --output text)"
ws_commit "billing: exports bucket, events topic, exporter role"
sed -i 's|key          = "billing/terraform.tfstate"|key          = "prod/billing/terraform.tfstate"|' stacks/billing/versions.tf
ws_commit "chore: tidy backend keys to <env>/<stack>/terraform.tfstate" "Jordan (platform)"
