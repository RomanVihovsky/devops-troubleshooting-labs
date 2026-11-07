sed -i '/^dependency "app"/,/^}/d; s/^  app_sg_id = dependency.app.outputs.sg_id.*$/  app_sg_id = "" # the rule lives in db-access/' live/prod/network/terragrunt.hcl
mkdir -p live/prod/db-access
cat > live/prod/db-access/terragrunt.hcl <<'TF'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//db-access"
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    db_sg_id = "sg-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "app" {
  config_path = "../app"
  mock_outputs = {
    sg_id = "sg-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  db_sg_id     = dependency.network.outputs.db_sg_id
  client_sg_id = dependency.app.outputs.sg_id
}
TF
tg_apply_all live/prod
