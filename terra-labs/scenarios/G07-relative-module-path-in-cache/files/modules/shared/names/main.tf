variable "env" {
  type = string
}

variable "service" {
  type = string
}

output "prefix" {
  value = "acme-${var.env}-${var.service}"
}
