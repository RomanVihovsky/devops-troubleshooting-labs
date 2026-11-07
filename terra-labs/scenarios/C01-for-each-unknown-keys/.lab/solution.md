# Solution - for_each keys must be known at plan time

**Root cause**: `for_each = toset(aws_s3_bucket.logs[*].bucket)` keys the access blocks by bucket
names that contain `random_id.suffix.hex`. In prod those names are in state; in a brand-new env they
are "(known after apply)" - and Terraform must know every instance key while planning.

**Fix**: key by static data you own, look the resource up by that key:
```hcl
resource "aws_s3_bucket_public_access_block" "logs" {
  for_each = toset(var.log_buckets)
  bucket   = aws_s3_bucket.logs[index(var.log_buckets, each.key)].id
}
moved {   # x3, prod only (no-op in dr)
  from = aws_s3_bucket_public_access_block.logs["acme-prod-access-logs-1a2b3c"]
  to   = aws_s3_bucket_public_access_block.logs["access"]
}
```
(Cleaner long-term: `for_each` on the buckets too - `for_each = aws_s3_bucket.logs` is fine because a
resource map's *keys* are static even when its values are not.)

**Interview notes**
* Values may be unknown at plan; for_each **keys** and `count` may not. Unknown keys -> this error.
* `-target` is an escape hatch for recovery, not a design: every new environment would need it, and
  CI never does it.
* Changing instance keys = refactor = `moved` blocks, otherwise replacement.
