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

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "bucket_name" {
  type = string
}

resource "aws_security_group" "app" {
  name   = "${var.env}-app"
  vpc_id = var.vpc_id
}

resource "aws_ssm_parameter" "config" {
  name = "/${var.env}/app/config"
  type = "String"
  insecure_value = jsonencode({
    vpc_id    = var.vpc_id
    subnet_id = var.subnet_id
    bucket    = var.bucket_name
  })
}
