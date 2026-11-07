terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "env" {
  type = string
}

resource "aws_ssm_parameter" "setting" {
  for_each = { channel = "#ops-alerts", severity = "high" }

  name           = "/${var.env}/notifier/${each.key}"
  type           = "String"
  insecure_value = each.value
}
