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
    key          = "staging/web-config/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "env" {
  type = string
}

variable "debug" {
  type    = bool
  default = false
}

resource "aws_sns_topic" "events" {
  name = "${var.env}-web-events"
}

resource "aws_ssm_parameter" "setting" {
  for_each = {
    log_level    = var.debug ? "debug" : "info"
    events_topic = aws_sns_topic.events.arn
  }

  name           = "/${var.env}/web/${each.key}"
  type           = "String"
  insecure_value = each.value
}
