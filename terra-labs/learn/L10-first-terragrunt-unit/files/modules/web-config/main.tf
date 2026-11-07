# Plain module: no backend, no provider block - Terragrunt generates both.
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "env" {
  type = string
}

variable "app_name" {
  type = string
}

variable "settings" {
  type    = map(string)
  default = {}
}

resource "aws_s3_bucket" "assets" {
  bucket = "acme-${var.env}-${var.app_name}-assets"
}

resource "aws_ssm_parameter" "setting" {
  for_each = var.settings

  name           = "/${var.env}/${var.app_name}/${each.key}"
  type           = "String"
  insecure_value = each.value
}

output "assets_bucket" {
  value = aws_s3_bucket.assets.bucket
}
