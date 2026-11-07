# Shared by every unit under live/: state in S3, provider config, common inputs.
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

    # lab: the fake AWS (moto) cannot evaluate aws:SecureTransport, so `backend bootstrap`
    # must not attach the EnforcedTLS bucket policy (in real AWS: keep it).
    skip_bucket_enforced_tls = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "eu-central-1"
      default_tags {
        tags = {
          env        = "${local.env}"
          managed-by = "terragrunt"
        }
      }
    }
  EOF
}

inputs = {
  env = local.env
}
