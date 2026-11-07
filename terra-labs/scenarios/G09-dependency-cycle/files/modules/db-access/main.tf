# Lets one security group reach the database security group.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "db_sg_id" {
  type = string
}

variable "client_sg_id" {
  type = string
}

variable "port" {
  type    = number
  default = 5432
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id            = var.db_sg_id
  referenced_security_group_id = var.client_sg_id
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
}
