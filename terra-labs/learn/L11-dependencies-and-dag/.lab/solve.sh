cat > live/dev/app/terragrunt.hcl <<'TF'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//app"
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    vpc_id    = "vpc-00000000"
    subnet_id = "subnet-00000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "data" {
  config_path = "../data"

  mock_outputs = {
    bucket_name = "mock-bucket"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  vpc_id      = dependency.network.outputs.vpc_id
  subnet_id   = dependency.network.outputs.subnet_id
  bucket_name = dependency.data.outputs.bucket_name
}
TF
run_logged "$SETUP_LOG" tg live/dev run --all -- plan -input=false -no-color
(cd live/dev && terragrunt run --all --non-interactive --log-level error --report-file report.json -- \
  apply -auto-approve -input=false -no-color) >> "$SETUP_LOG" 2>&1
