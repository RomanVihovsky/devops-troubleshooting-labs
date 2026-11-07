resource "aws_sns_topic" "alerts" {
  name = "platform-alerts"
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "acme-build-artifacts"
}
