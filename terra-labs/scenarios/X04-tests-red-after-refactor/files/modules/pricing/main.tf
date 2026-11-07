# Gross price in cents, after discount and VAT. Commercial rounding to whole cents.
variable "net_cents" {
  type = number
}

variable "vat_percent" {
  type    = number
  default = 19
}

variable "discount_percent" {
  type    = number
  default = 0

  validation {
    condition     = var.discount_percent >= 0 && var.discount_percent <= 50
    error_message = "discount_percent must be between 0 and 50."
  }
}

locals {
  discounted = var.net_cents * (100 - var.discount_percent) / 100
  gross      = local.discounted * (100 + var.vat_percent) / 100
}

output "gross_cents" {
  value = floor(local.gross + 0.5)
}
