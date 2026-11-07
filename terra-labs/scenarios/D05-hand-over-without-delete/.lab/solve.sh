cat >> stacks/platform-shared/main.tf <<'TF'

# handed over to the data team (INFRA-188) - forget, don't destroy
removed {
  from = aws_s3_bucket.datasets
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket_versioning.datasets
  lifecycle {
    destroy = false
  }
}
TF
apply stacks/platform-shared
