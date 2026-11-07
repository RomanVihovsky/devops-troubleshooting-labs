terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "acme-tfstate"
    key          = "catalog-api/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "page_size" {
  type    = number
  default = 50
}

# Product catalog snapshots.
resource "aws_s3_bucket" "catalog" {
  bucket = "acme-catalog-api-data"
}

resource "aws_ssm_parameter" "page_size" {
  name           = "/catalog-api/page-size"
  type           = "String"
  insecure_value = tostring(var.page_size)
}

resource "aws_iam_role" "api" {
  name = "catalog-api"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "read" {
  name = "read-catalog"
  role = aws_iam_role.api.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["${aws_s3_bucket.catalog.arn}/*"]
    }]
  })
}

output "bucket" {
  value = aws_s3_bucket.catalog.bucket
}
