## Hint 1
Deleting a resource block means "destroy it" to Terraform. You want "forget it".

## Hint 2
Terraform 1.7+ has a `removed` block - with a `lifecycle` that says whether to destroy.

## Hint 3
```
removed {
  from = aws_s3_bucket.datasets
  lifecycle { destroy = false }
}
```
plus the same for `aws_s3_bucket_versioning.datasets`. Plan says "will no longer be managed". Apply.
