# Product images. Never recreate this bucket.
resource "aws_s3_bucket" "media" {
  bucket = "acme-media-assets"
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_arn" {
  value = aws_s3_bucket.media.arn
}
