# Monthly reports. Ownership moves to the data team (their stack will import it).
resource "aws_s3_bucket" "reports" {
  bucket = "acme-legacy-reports"
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

# TODO 1: import the feature flags /legacy/flags/* (one import block with for_each)
# TODO 2: import the IAM role legacy-reporting (use -generate-config-out)
# TODO 3: hand the reports bucket over without deleting it
