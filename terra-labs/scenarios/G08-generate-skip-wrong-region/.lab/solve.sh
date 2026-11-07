rm modules/notifier/provider.tf
sed -i 's/  if_exists = "skip"/  if_exists = "overwrite_terragrunt"/; s/^# Don.t clobber.*$/# The provider is always generated here - modules must not configure providers./' live/root.hcl
run_logged "$SETUP_LOG" tg live/prod/notifier apply -auto-approve -input=false -no-color \
  '-replace=aws_ssm_parameter.setting["channel"]' '-replace=aws_ssm_parameter.setting["severity"]'
aws ssm delete-parameters --region us-east-1 --names /prod/notifier/channel /prod/notifier/severity >/dev/null 2>&1 || true
