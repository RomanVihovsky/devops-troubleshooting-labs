# S01 - a stale S3 lockfile left by a CI job that was OOM-killed mid-apply.
aws s3api create-bucket --bucket acme-tfstate \
  --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
aws s3api put-bucket-versioning --bucket acme-tfstate --versioning-configuration Status=Enabled

apply stacks/payments
echo '{"order":"r-1001","amount":"129.00 EUR"}' |
  aws s3 cp - s3://acme-payments-receipts/2026/11/05/r-1001.json >/dev/null

remember lineage "$(s3_state_lineage acme-tfstate payments/terraform.tfstate)"

# The lock object Terraform itself writes with use_lockfile = true, as left by the killed runner.
lock_id=$(cat /proc/sys/kernel/random/uuid)
remember lock_id "$lock_id"
printf '{"ID":"%s","Operation":"OperationTypeApply","Info":"","Who":"gitlab-runner@ci-runner-07","Version":"%s","Created":"%sT02:13:41.528Z","Path":"acme-tfstate/payments/terraform.tfstate"}' \
  "$lock_id" "$TERRAFORM_VERSION" "$(date -u -d yesterday +%F)" |
  aws s3 cp - s3://acme-tfstate/payments/terraform.tfstate.tflock >/dev/null
