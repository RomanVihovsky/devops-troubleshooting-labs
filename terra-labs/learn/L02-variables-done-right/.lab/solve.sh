cat > app-config/main.tf <<'TF'
terraform {
  required_version = ">= 1.10"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "env" {
  type        = string
  description = "Deployment environment."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be one of dev, staging, prod."
  }
}

variable "service" {
  type = object({
    name     = string
    port     = optional(number, 8080)
    replicas = optional(number, 2)
    tags     = optional(map(string), {})
  })

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.service.name))
    error_message = "service.name: lowercase letters, digits and dashes, 3-21 chars, starting with a letter."
  }
  validation {
    condition     = var.service.port >= 1024 && var.service.port <= 65535
    error_message = "service.port must be between 1024 and 65535."
  }
  validation {
    condition     = var.env != "prod" || var.service.replicas >= 3
    error_message = "prod needs at least 3 replicas."
  }
}

variable "api_token" {
  type      = string
  sensitive = true
}

locals {
  config = {
    env      = var.env
    name     = var.service.name
    port     = var.service.port
    replicas = var.service.replicas
    tags     = merge({ env = var.env }, var.service.tags)
  }
}

resource "local_file" "config" {
  filename = "${path.module}/out/${var.env}-${var.service.name}.json"
  content  = jsonencode(local.config)
}

resource "local_sensitive_file" "token" {
  filename = "${path.module}/out/${var.env}-${var.service.name}.token"
  content  = var.api_token
}

output "config_file" {
  value = local_file.config.filename
}
TF
run_logged "$SETUP_LOG" tf app-config init -input=false -no-color
run_logged "$SETUP_LOG" tf app-config apply -auto-approve -input=false -no-color -var-file=env/staging.tfvars
