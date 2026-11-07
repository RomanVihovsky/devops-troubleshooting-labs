terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # TODO: backend "s3" - partial configuration, the settings go to backend.hcl
}

provider "aws" {
  region = "eu-central-1"
}
