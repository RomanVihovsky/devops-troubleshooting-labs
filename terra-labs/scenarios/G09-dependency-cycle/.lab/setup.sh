sed -i '/^dependency "app"/,/^}/d; s/^  app_sg_id = dependency.app.outputs.sg_id.*$/  app_sg_id = ""/' live/prod/network/terragrunt.hcl
run_logged "$SETUP_LOG" tg live/prod/network backend bootstrap
tg_apply_all live/prod
remember db_sg "$(aws ec2 describe-security-groups --filters Name=group-name,Values=prod-db --query 'SecurityGroups[0].GroupId' --output text)"
ws_commit "prod: network + app"
cp "$SCN/files/live/prod/network/terragrunt.hcl" live/prod/network/terragrunt.hcl
ws_commit "security: only the app tier may reach the database" "Security team"
