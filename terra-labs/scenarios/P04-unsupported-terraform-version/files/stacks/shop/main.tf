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
    key          = "shop/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "tags" {
  source      = "../../modules/legacy-tags"
  team        = "shop"
  cost_center = "cc-4711"
}

resource "aws_sns_topic" "orders" {
  name = "shop-orders"
  tags = module.tags.tags
}
