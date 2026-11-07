cat > live/root.hcl <<'TF'
locals {
  env_cfg = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
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
          env        = "${local.env_cfg.env}"
          managed-by = "terragrunt"
        }
      }
    }
  EOF
}

inputs = {
  env      = local.env_cfg.env
  replicas = local.env_cfg.replicas
}
TF
printf 'locals {\n  env      = "dev"\n  replicas = 1\n}\n' > live/dev/env.hcl
printf 'locals {\n  env      = "prod"\n  replicas = 3\n}\n' > live/prod/env.hcl
for e in dev prod; do
  cat > "live/$e/web/terragrunt.hcl" <<'TF'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//web"
}
TF
  cat > "live/$e/audit/terragrunt.hcl" <<'TF'
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//audit"
}

# Audit logging runs in prod; elsewhere only on request: run --all --feature audit=true
feature "audit" {
  default = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals.env == "prod"
}

exclude {
  if      = !feature.audit.value
  actions = ["all"]
}
TF
done
