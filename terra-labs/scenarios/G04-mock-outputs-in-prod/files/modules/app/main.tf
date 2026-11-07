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

variable "uploads_bucket_name" {
  type = string
}

variable "uploads_bucket_arn" {
  type = string
}

resource "aws_iam_role" "app" {
  name = "${var.env}-app"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "uploads" {
  name = "uploads"
  role = aws_iam_role.app.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject"]
      Resource = ["${var.uploads_bucket_arn}/*"]
    }]
  })
}

# The app reads its bucket name from here at startup.
resource "aws_ssm_parameter" "uploads_bucket" {
  name  = "/${var.env}/app/uploads-bucket"
  type  = "String"
  value = var.uploads_bucket_name
}
