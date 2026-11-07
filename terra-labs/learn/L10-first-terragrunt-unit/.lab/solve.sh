cat > live/root.hcl <<'TF'
# Shared configuration, included by every unit under live/.
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
TF
cat > live/dev/env.hcl <<'TF'
locals {
  env = "dev"
}
TF
cat > live/dev/web/terragrunt.hcl <<'TF'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//web-config"
}

inputs = {
  app_name = "web"
  settings = {
    log_level = "debug"
    feature_x = "on"
  }
}
TF
run_logged "$SETUP_LOG" tg live/dev/web backend bootstrap
run_logged "$SETUP_LOG" tg live/dev/web apply -auto-approve -input=false -no-color
(cd live && terragrunt hcl fmt --log-level error)
