# Solution - pass the aliased provider to the module

**Root cause**: modules inherit the **default** (unaliased) provider configuration unless told
otherwise. Declaring `provider "aws" { alias = "dr" }` does nothing until something uses it.

**Fix**
```hcl
module "replica" {
  source    = "../../modules/replica-bucket"
  name      = "acme-media-replica"
  providers = { aws = aws.dr }
}
```
Then **replace** the replica: `terraform apply -replace=module.replica.aws_s3_bucket.this
-replace=module.replica.aws_s3_bucket_versioning.this`. Re-wiring alone shows "no changes": the provider
reads the existing bucket wherever it is, so nothing would ever move. Moving regions = new bucket.

**Interview notes**
* Modules that need several configurations declare `configuration_aliases = [aws.primary, aws.dr]`
  in `required_providers`; callers must then map all of them.
* AWS provider 6.0 added a `region` argument to (almost) every resource: multi-region without aliases.
* Verify region-sensitive things in tests (`terraform test` assert on `.region`) - this went unnoticed for months.
