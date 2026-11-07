sed -i 's|^  mock_outputs = {|  mock_outputs_allowed_terraform_commands = ["validate", "plan"]\n\n  mock_outputs = {|' \
  live/prod/app/terragrunt.hcl
run_logged "$SETUP_LOG" tg live/prod run --all -- apply -auto-approve -input=false -no-color
