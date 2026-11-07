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
    key          = "events/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "orders" {
  source = "git::https://git.acme.example/platform/tf-module-topic.git?ref=v1.4.0"
  name   = "orders-events"
}

module "refunds" {
  source = "git::https://git.acme.example/platform/tf-module-topic.git?ref=v1.4.0"
  name   = "refunds-events"
}
