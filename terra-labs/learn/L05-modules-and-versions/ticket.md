# L05 · Modules and versions
**Learn** · git module sources, version pinning, moved blocks · ~25 min

`stacks/media` manages its bucket with inline resources. The platform team publishes a bucket
module with sane defaults at `https://git.acme.example/platform/tf-module-bucket.git` (tags
`v1.0.0`, `v1.1.0`). Switch to it - **without** recreating the bucket: it holds the product images.

1. Look at the module first: `git clone https://git.acme.example/platform/tf-module-bucket.git /tmp/m`,
   `git -C /tmp/m tag`, read its README and variables. What does v1.1.0 add?
2. Replace the inline resources with `module "media"` from that repo, **pinned to `v1.1.0`**
   (`git::https://...?ref=v1.1.0`), with `sse_algorithm = "aws:kms"`.
3. Add `moved` blocks so the existing bucket and its versioning move into the module.
4. `terraform init` (downloads the module), `terraform plan`: **0 to destroy**, only the new
   encryption configuration is added. Keep the `bucket_arn` output working. Apply.

**Test**: state holds the module's bucket and versioning and no inline ones; the bucket was not
recreated and still has its files; the bucket is encrypted with `aws:kms`; the module
comes from tag `v1.1.0`; `bucket_arn` still works; a CI plan shows no changes.
