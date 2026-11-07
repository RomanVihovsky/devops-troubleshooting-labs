terraform {
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

module "names" {
  source  = "../shared/names"
  env     = var.env
  service = "checkout"
}

resource "aws_ssm_parameter" "prefix" {
  name           = "/${var.env}/checkout/prefix"
  type           = "String"
  insecure_value = module.names.prefix
}
