terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

variable "app" {
  type = string
}

locals {
  settings = {
    log_level = "warn"
    tracing   = "on"
    page_size = "48"
  }
}

resource "aws_ssm_parameter" "setting" {
  for_each = local.settings

  name           = "/${var.app}/${each.key}"
  type           = "String"
  insecure_value = each.value
}
