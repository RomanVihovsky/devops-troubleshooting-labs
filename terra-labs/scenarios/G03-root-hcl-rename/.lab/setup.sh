sed -i 's/find_in_parent_folders()/find_in_parent_folders("root.hcl")/' live/prod/*/terragrunt.hcl
run_logged "$SETUP_LOG" tg live/prod/network backend bootstrap
tg_apply_all live/prod
sed -i 's/find_in_parent_folders("root.hcl")/find_in_parent_folders()/' live/prod/*/terragrunt.hcl
mv live/root.hcl live/terragrunt.hcl
ws_commit "prod: network + app"
mv live/terragrunt.hcl live/root.hcl
ws_commit "chore(tg 1.x): rename root terragrunt.hcl to root.hcl" "Jordan (platform)"
