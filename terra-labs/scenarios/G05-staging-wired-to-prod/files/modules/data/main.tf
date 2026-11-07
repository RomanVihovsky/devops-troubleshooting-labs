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

resource "aws_s3_bucket" "data" {
  bucket = "acme-${var.env}-app-data"
}

output "bucket_name" {
  value = aws_s3_bucket.data.bucket
}
