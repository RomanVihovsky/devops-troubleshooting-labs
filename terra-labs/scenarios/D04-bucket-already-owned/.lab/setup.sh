state_bucket
mv stacks/analytics/exports.tf "$STATE_DIR/exports.tf"
apply stacks/analytics
ws_commit "analytics: jobs topic"
# the outage workaround, by hand
aws s3api create-bucket --bucket acme-analytics-exports --create-bucket-configuration LocationConstraint=eu-central-1 >/dev/null
echo 'day,rows' | aws s3 cp - s3://acme-analytics-exports/2026-10-14.csv >/dev/null
remember_bucket acme-analytics-exports
mv "$STATE_DIR/exports.tf" stacks/analytics/exports.tf
ws_commit "analytics: manage the exports bucket in code" "Noor (analytics)"
run_logged "$SETUP_LOG" tf stacks/analytics apply -auto-approve -input=false -no-color || true   # the failed CI apply
