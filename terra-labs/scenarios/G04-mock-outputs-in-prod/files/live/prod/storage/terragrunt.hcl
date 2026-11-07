include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//storage"
}

inputs = {
  bucket_name = "acme-prod-uploads"
}
