# Customer receipts (PDFs) - retained for 10 years. Never recreate this bucket.
resource "aws_s3_bucket" "receipts" {
  bucket = "acme-payments-receipts"
}

resource "aws_s3_bucket_versioning" "receipts" {
  bucket = aws_s3_bucket.receipts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_sns_topic" "events" {
  name = "payments-events"
}

resource "aws_ssm_parameter" "events_topic_arn" {
  name  = "/payments/events-topic-arn"
  type  = "String"
  value = aws_sns_topic.events.arn
}
