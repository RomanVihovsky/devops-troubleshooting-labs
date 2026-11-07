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

variable "cidr" {
  type = string
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr
  tags       = { Name = "${var.env}-vpc" }
}

resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.this.id
  cidr_block = cidrsubnet(var.cidr, 8, 1)
  tags       = { Name = "${var.env}-app" }
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.app.id
}
