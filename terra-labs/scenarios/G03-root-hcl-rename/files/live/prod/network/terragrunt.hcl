include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules//network"
}

inputs = {
  cidr = "10.24.0.0/16"
}
