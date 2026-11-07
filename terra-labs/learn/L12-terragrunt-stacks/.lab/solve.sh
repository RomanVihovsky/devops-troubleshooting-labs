cat > live/dev/terragrunt.stack.hcl <<'TF'
locals {
  shards = toset(["blue", "green"])
}

unit "network" {
  source = "../../catalog/units/network"
  path   = "network"

  values = {
    cidr = "10.40.0.0/16"
  }
}

unit "data" {
  source = "../../catalog/units/data"
  path   = "data"
}

unit "app" {
  expansion {
    for_each = local.shards
  }

  source = "../../catalog/units/app"
  path   = "app-${each.key}"

  autoinclude {
    dependency "network" {
      config_path = unit.network.path
      mock_outputs = {
        vpc_id    = "vpc-00000000"
        subnet_id = "subnet-00000000"
      }
      mock_outputs_allowed_terraform_commands = ["validate", "plan"]
    }

    dependency "data" {
      config_path = unit.data.path
      mock_outputs = {
        bucket_name = "mock-bucket"
      }
      mock_outputs_allowed_terraform_commands = ["validate", "plan"]
    }

    inputs = {
      vpc_id      = dependency.network.outputs.vpc_id
      subnet_id   = dependency.network.outputs.subnet_id
      bucket_name = dependency.data.outputs.bucket_name
      env         = "dev-${each.key}"
    }
  }
}
TF
git add -A && git -c user.name=You -c user.email=you@acme.example commit -qm "dev as a stack"
(cd live/dev && terragrunt stack generate --log-level error &&
  terragrunt stack run --non-interactive --log-level error --backend-bootstrap -- apply -auto-approve -input=false -no-color) >> "$SETUP_LOG" 2>&1
