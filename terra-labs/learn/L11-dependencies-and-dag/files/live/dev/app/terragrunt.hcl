include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//app"
}

# TODO: dependency "network" and dependency "data" (mock_outputs for validate/plan only)

inputs = {
  vpc_id      = "TODO"
  subnet_id   = "TODO"
  bucket_name = "TODO"
}
