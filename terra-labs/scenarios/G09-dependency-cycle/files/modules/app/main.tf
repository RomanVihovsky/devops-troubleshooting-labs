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

resource "aws_security_group" "app" {
  name   = "${var.env}-app"
  vpc_id = var.vpc_id
}

output "sg_id" {
  value = aws_security_group.app.id
}
