run_logged "$SETUP_LOG" tf stacks/billing init -migrate-state -force-copy -input=false -no-color
aws s3 rm s3://acme-tfstate/billing/terraform.tfstate >/dev/null
