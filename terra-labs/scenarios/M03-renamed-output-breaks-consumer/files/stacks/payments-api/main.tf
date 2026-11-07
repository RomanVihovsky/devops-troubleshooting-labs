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
    key          = "payments-api/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "acme-tfstate"
    key    = "network/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_security_group" "api" {
  name   = "payments-api"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}

resource "aws_ssm_parameter" "subnet" {
  name           = "/payments-api/subnet-id"
  type           = "String"
  insecure_value = data.terraform_remote_state.network.outputs.subnet_id
}
