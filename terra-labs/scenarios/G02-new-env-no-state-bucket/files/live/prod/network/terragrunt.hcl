include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//network"
}

inputs = {
  cidr = "10.22.0.0/16"
}
