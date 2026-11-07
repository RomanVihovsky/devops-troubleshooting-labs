variable "env" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging or prod."
  }
}

variable "team" {
  type = string
}

variable "name" {
  type = string
}

locals {
  prefix = join("-", ["acme", var.env, var.team])
}

output "prefix" {
  value = local.prefix
}

output "bucket_name" {
  value = "${local.prefix}-${var.name}"
}

output "tags" {
  value = {
    env        = var.env
    team       = var.team
    managed-by = "terraform"
  }
}
