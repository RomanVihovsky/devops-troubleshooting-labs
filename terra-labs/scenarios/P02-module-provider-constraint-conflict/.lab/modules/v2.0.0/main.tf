terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

variable "topic_name" {
  type = string
}

variable "kms_key_id" {
  type        = string
  default     = "alias/aws/sns"
  description = "KMS key for server-side encryption."
}

resource "aws_sns_topic" "this" {
  name              = var.topic_name
  kms_master_key_id = var.kms_key_id
}

output "arn" {
  value = aws_sns_topic.this.arn
}
