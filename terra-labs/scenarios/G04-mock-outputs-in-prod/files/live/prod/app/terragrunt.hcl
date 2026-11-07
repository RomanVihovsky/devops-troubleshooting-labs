include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//app"
}

dependency "storage" {
  config_path = "../storage"

  # so that `plan` works before storage has been applied
  mock_outputs = {
    bucket_name = "mock-uploads-bucket"
    bucket_arn  = "arn:aws:s3:::mock-uploads-bucket"
  }
}

inputs = {
  uploads_bucket_name = dependency.storage.outputs.bucket_name
  uploads_bucket_arn  = dependency.storage.outputs.bucket_arn
}
