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
    key          = "network/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.90.0.0/16"
  tags       = { Name = "main" }
}

resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.90.1.0/24"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "app_subnet_id" {
  description = "Subnet for application workloads."
  value       = aws_subnet.app.id
}
