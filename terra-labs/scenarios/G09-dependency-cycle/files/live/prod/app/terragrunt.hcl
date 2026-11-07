include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//app"
}

dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  vpc_id = dependency.network.outputs.vpc_id
}
