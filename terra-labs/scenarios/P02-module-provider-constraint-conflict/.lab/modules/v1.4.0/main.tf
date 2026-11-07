terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # pin the major: no surprises from provider upgrades
    }
  }
}

variable "name" {
  type = string
}

resource "aws_sns_topic" "this" {
  name              = var.name
  kms_master_key_id = var.kms_key_id
}

output "arn" {
  value = aws_sns_topic.this.arn
}

variable "kms_key_id" {
  type        = string
  default     = "alias/aws/sns"
  description = "KMS key for server-side encryption (since v1.4.0)."
}
