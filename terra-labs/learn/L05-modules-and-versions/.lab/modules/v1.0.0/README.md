# tf-module-bucket

Versioned S3 bucket.

```hcl
module "assets" {
  source = "git::https://git.acme.example/platform/tf-module-bucket.git?ref=v1.0.0"
  name   = "acme-assets"
}
```
Outputs: `name`, `arn`.
