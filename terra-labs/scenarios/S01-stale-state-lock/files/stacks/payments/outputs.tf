output "receipts_bucket" {
  value = aws_s3_bucket.receipts.bucket
}

output "events_topic_arn" {
  value = aws_sns_topic.events.arn
}
