terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "s3" {} # env/<env>.s3.tfbackend
}

provider "aws" {
  region = "eu-central-1"
}

variable "env" {
  type = string
}

variable "log_buckets" {
  type    = list(string)
  default = ["access", "audit", "app"]
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "logs" {
  count  = length(var.log_buckets)
  bucket = "acme-${var.env}-${var.log_buckets[count.index]}-logs-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  for_each = toset(aws_s3_bucket.logs[*].bucket)

  bucket                  = each.key
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
