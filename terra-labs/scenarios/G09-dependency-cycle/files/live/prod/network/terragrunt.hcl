include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//network"
}

dependency "app" {
  config_path = "../app"
  mock_outputs = {
    sg_id = "sg-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  app_sg_id = dependency.app.outputs.sg_id # security: only the app may reach the db
}
