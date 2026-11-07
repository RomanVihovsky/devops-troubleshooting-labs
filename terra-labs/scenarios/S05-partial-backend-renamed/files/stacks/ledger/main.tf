terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # settings per environment: backend/<env>.hcl
  backend "s3" {}
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_sns_topic" "postings" {
  name = "ledger-postings"
}

resource "aws_ssm_parameter" "retention" {
  name           = "/ledger/retention-days"
  type           = "String"
  insecure_value = "3650"
}
