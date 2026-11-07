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
    key          = "media-dr/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "dr"
  region = "eu-west-1"
}

resource "aws_s3_bucket" "primary" {
  bucket = "acme-media-primary"
}

# DR copy in Ireland
module "replica" {
  source = "../../modules/replica-bucket"
  name   = "acme-media-replica"
}
