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
    key          = "payments/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_ssm_parameter" "limit" {
  name           = "/payments/max-transaction-eur"
  type           = "String"
  insecure_value = "5000"
}

resource "aws_sns_topic" "alerts" {
  name = "payments-alerts"
}
