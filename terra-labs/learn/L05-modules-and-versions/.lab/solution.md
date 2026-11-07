# Solution - L05

```hcl
module "media" {
  source          = "git::https://git.acme.example/platform/tf-module-bucket.git?ref=v1.1.0"
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
output "bucket_arn" { value = module.media.arn }
```
Plan: `1 to add, 0 to change, 0 to destroy` (+ "has moved to" lines).

**Takeaways**
* Refactoring changes **addresses**, not infrastructure. Without `moved`, Terraform sees "destroy
  aws_s3_bucket.media, create module.media.aws_s3_bucket.this" (incident D02). `moved` blocks are
  reviewed in the PR and replayed in every environment; `terraform state mv` is a one-off manual edit.
  Keep them for a while (until every env has applied), then delete.
* Pin modules to immutable refs. A tag can be moved by force-push; for supply-chain safety pin a
  commit SHA (`?ref=<sha>`) or use a registry with checksums.
* `terraform init -upgrade` re-resolves modules and providers; `terraform get` only modules.
* The lab's `git.acme.example` is local: `GIT_CONFIG_GLOBAL` rewrites it with `url.insteadOf` -
  the same trick works for mirrors in air-gapped CI.
