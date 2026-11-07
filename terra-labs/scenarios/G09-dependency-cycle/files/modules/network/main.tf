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

variable "app_sg_id" {
  type    = string
  default = ""
}

resource "aws_vpc" "main" {
  cidr_block = "10.95.0.0/16"
  tags       = { Name = "${var.env}-vpc" }
}

resource "aws_security_group" "db" {
  name   = "${var.env}-db"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "app_to_db" {
  count = var.app_sg_id == "" ? 0 : 1

  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.app_sg_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "db_sg_id" {
  value = aws_security_group.db.id
}
