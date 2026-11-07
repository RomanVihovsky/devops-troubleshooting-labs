# Solution - adopt the hand-made bucket with an import block

**Root cause**: the bucket exists (created by hand), but not in state, so Terraform tries to create it.
S3 bucket names are global; the API answers `BucketAlreadyOwnedByYou`.

**Fix**
```hcl
import {
  to = aws_s3_bucket.exports
  id = "acme-analytics-exports"
}
```
Plan: 1 import, 1 add (versioning). Apply, then plan -> clean.

**Interview notes**
* Import blocks are reviewed in the PR and plan-able; `terraform import` CLI is not.
* After import compare carefully: anything in code that differs from reality is changed in the same apply.
* Never "fix" this by deleting the bucket or renaming it in code.
