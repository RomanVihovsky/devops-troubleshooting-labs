# tf-module-bucket

Versioned S3 bucket. Since v1.1.0: default encryption, `sse_algorithm` = `AES256` (default) or `aws:kms`.

```hcl
module "assets" {
  source = "git::https://git.acme.example/platform/tf-module-bucket.git?ref=v1.1.0"
  name   = "acme-assets"
}
```
Outputs: `name`, `arn`.
