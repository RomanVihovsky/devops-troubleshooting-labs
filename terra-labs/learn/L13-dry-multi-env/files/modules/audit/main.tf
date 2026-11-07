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

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/${var.env}/audit"
  retention_in_days = 365
}
