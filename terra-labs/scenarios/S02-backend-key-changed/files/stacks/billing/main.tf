resource "aws_s3_bucket" "exports" {
  bucket = "acme-billing-exports"
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sns_topic" "events" {
  name = "billing-events"
}

resource "aws_ssm_parameter" "currency" {
  for_each = toset(["eur", "usd", "gbp"])

  name           = "/billing/currencies/${each.key}"
  type           = "String"
  insecure_value = "enabled"
}

resource "aws_iam_role" "exporter" {
  name = "billing-exporter"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}
