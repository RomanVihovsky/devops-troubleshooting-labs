terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "name" {
  type = string
}

resource "aws_sns_topic" "this" {
  name = var.name
}

output "arn" {
  value = aws_sns_topic.this.arn
}
