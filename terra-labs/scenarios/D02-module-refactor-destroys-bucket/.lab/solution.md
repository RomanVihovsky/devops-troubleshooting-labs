# Solution - moved blocks into a module

**Root cause**: moving resources into a module changes their addresses
(`aws_s3_bucket.uploads` -> `module.uploads.aws_s3_bucket.this`). Terraform plans destroy + create.
For a bucket full of data the destroy fails (BucketNotEmpty) - after it may already have destroyed
the versioning and public access block. Worst case with `force_destroy`: data gone.

**Fix**
```hcl
moved {
  from = aws_s3_bucket.uploads
  to   = module.uploads.aws_s3_bucket.this
}
# + aws_s3_bucket_versioning, aws_s3_bucket_public_access_block
```

**Interview notes**
* Every refactor PR should show `0 to destroy` (or explain each one). Make CI fail on unexpected
  deletes of stateful resources (L14 policy, `prevent_destroy`).
* `moved` into/out of modules works for local and remote modules; module authors can ship `moved`
  blocks inside the module for renames (incident M02).
