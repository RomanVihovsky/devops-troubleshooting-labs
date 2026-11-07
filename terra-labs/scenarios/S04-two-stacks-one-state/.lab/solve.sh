sed -i 's|key          = "search/terraform.tfstate"|key          = "recs/terraform.tfstate"|' stacks/recs/versions.tf
run_logged "$SETUP_LOG" tf stacks/recs init -reconfigure -input=false -no-color
run_logged "$SETUP_LOG" tf stacks/recs apply -auto-approve -input=false -no-color
