# Creates the bucket that stores every other stack's state.
# Its own state stays local (chicken and egg) - in real life: keep it safe, or import the bucket later.
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# TODO: bucket "acme-tfstate" + versioning + default encryption (aws:kms) + public access block
