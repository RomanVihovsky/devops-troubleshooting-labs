state_bucket
run_logged "$SETUP_LOG" tf stacks/ledger init -input=false -no-color -backend-config=backend/prod.hcl
run_logged "$SETUP_LOG" tf stacks/ledger apply -auto-approve -input=false -no-color
ws_commit "ledger: postings topic, retention"
git mv stacks/ledger/backend/prod.hcl stacks/ledger/backend/prod.s3.tfbackend
sed -i 's|backend/<env>.hcl|backend/<env>.s3.tfbackend|' stacks/ledger/main.tf
ws_commit "chore: use the recommended .tfbackend extension" "Alex (platform)"
