cat > stacks/media/main.tf <<'TF'
# Product images. Never recreate this bucket.
module "media" {
  source = "git::https://git.acme.example/platform/tf-module-bucket.git?ref=v1.1.0"

  name            = "acme-media-assets"
  sse_algorithm   = "aws:kms"
}

moved {
  from = aws_s3_bucket.media
  to   = module.media.aws_s3_bucket.this
}

moved {
  from = aws_s3_bucket_versioning.media
  to   = module.media.aws_s3_bucket_versioning.this
}

output "bucket_arn" {
  value = module.media.arn
}
TF
apply stacks/media
