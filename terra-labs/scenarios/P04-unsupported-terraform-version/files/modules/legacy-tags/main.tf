# Vendored from git.acme.example/platform/terraform-legacy (archived).
terraform {
  required_version = "~> 1.9.0"
}

variable "team" {
  type = string
}

variable "cost_center" {
  type = string
}

output "tags" {
  value = {
    team        = var.team
    cost-center = var.cost_center
    managed-by  = "terraform"
  }
}
