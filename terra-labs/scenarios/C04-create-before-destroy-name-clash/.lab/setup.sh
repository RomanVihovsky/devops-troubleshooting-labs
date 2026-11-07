printf 'color = "blue"\n' > stacks/api/terraform.tfvars
apply stacks/api
ws_commit "api: blue"
printf 'color = "green"\n' > stacks/api/terraform.tfvars
ws_commit "deploy: green" "API team"
run_logged "$SETUP_LOG" tf stacks/api apply -auto-approve -input=false -no-color || true   # the failed deploy
