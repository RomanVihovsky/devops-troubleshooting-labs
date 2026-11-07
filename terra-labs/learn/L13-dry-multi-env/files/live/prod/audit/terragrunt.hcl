# copied from another unit and adjusted - keep in sync by hand (!)
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "acme-tg-state"
    key          = "prod/audit/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true

    # lab only: the fake AWS cannot evaluate aws:SecureTransport
    skip_bucket_enforced_tls = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOT
    provider "aws" {
      region = "eu-central-1"
      default_tags {
        tags = {
          env        = "prod"
          managed-by = "terragrunt"
        }
      }
    }
  EOT
}

terraform {
  source = "../../../modules//audit"
}

inputs = {
  env = "prod"
}
