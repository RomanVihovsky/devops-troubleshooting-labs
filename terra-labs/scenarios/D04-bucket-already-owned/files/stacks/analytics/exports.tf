resource "aws_s3_bucket" "exports" {
  bucket = "acme-analytics-exports"
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id
  versioning_configuration {
    status = "Enabled"
  }
}
