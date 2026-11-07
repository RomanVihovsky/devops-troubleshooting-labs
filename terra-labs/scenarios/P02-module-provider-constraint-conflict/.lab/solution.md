# Solution - provider constraints across the module tree

**Root cause**: Terraform picks **one** version per provider for the whole configuration. v1.4.0 of the
module pinned `aws ~> 5.0`; the root requires `~> 6.0`. No version satisfies both -> init fails.

**Diagnose**: `terraform providers` (constraints per module), the module's CHANGELOG.

**Fix**: upgrade to v2.0.0 (supports provider 6, has the encryption), apply its documented rename:
```hcl
module "orders" {
  source     = "git::https://git.acme.example/platform/tf-module-topic.git?ref=v2.0.0"
  topic_name = "orders-events"
}
```
`init -upgrade`, plan: in-place `kms_master_key_id` only.

**Interview notes**
* Reusable modules should declare **minimum** versions (`>= 6.0`), never upper bounds like `~> 5.0` -
  the root module owns the upper bound (and the lock file the exact version).
* Read changelogs before taking a major; a module rename without `moved` would have replaced topics
  (and dropped subscriptions) - incident M02.
