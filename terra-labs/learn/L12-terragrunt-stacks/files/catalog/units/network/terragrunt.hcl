# Unit template: network. Generated into live/<env>/.terragrunt-stack/<path>/ by `stack generate`.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}/modules//network"
}

inputs = {
  cidr = values.cidr
}
