resource "aws_s3_bucket" "exports" {
  bucket = "acme-inventory-exports"
}

resource "aws_ssm_parameter" "warehouse" {
  for_each = toset(["ber", "muc", "ham"])

  name           = "/inventory/warehouses/${each.key}"
  type           = "String"
  insecure_value = "active"
}
