terraform {
  required_version = ">= 1.10"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# TODO: types, defaults and validation - see the task
variable "env" {}

variable "service" {}

# TODO: variable "api_token"

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

# TODO: write var.api_token to out/<env>-<name>.token with local_sensitive_file

output "config_file" {
  value = local_file.config.filename
}
