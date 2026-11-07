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

variable "replicas" {
  type = number
}

resource "aws_s3_bucket" "assets" {
  bucket = "acme-${var.env}-web-assets"
}

resource "aws_ssm_parameter" "replicas" {
  name           = "/${var.env}/web/replicas"
  type           = "String"
  insecure_value = tostring(var.replicas)
}
