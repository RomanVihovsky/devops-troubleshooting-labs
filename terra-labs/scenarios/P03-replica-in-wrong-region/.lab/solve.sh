sed -i 's|  name   = "acme-media-replica"|  name   = "acme-media-replica"\n\n  providers = {\n    aws = aws.dr\n  }|' stacks/media-dr/main.tf
# re-wiring alone moves nothing: the existing bucket is read where it is -> replace it explicitly
run_logged "$SETUP_LOG" tf stacks/media-dr apply -auto-approve -input=false -no-color \
  -replace=module.replica.aws_s3_bucket.this -replace=module.replica.aws_s3_bucket_versioning.this
