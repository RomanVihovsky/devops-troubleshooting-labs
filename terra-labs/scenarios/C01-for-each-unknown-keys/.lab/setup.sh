state_bucket
run_logged "$SETUP_LOG" tf stacks/logs init -input=false -no-color -backend-config=env/prod.s3.tfbackend
# how prod was bootstrapped two years ago: -target first, then the rest
run_logged "$SETUP_LOG" tf stacks/logs apply -auto-approve -input=false -no-color -var-file=env/prod.tfvars -target=aws_s3_bucket.logs
run_logged "$SETUP_LOG" tf stacks/logs apply -auto-approve -input=false -no-color -var-file=env/prod.tfvars
remember prod_buckets "$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'acme-prod-')].[Name,CreationDate]" --output text | sort)"
