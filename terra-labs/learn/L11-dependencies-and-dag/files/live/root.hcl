locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "acme-tg-state"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true

    # lab only: the fake AWS cannot evaluate aws:SecureTransport
    skip_bucket_enforced_tls = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "eu-central-1"
    }
  EOF
}

inputs = {
  env = local.env
}
