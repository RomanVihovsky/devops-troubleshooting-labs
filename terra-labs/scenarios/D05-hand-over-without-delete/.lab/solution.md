# Solution - removed { destroy = false }

**Root cause**: deleting a resource block = desired state "absent" = destroy. To stop *managing*
something you must say so.

**Fix**
```hcl
removed {
  from = aws_s3_bucket.datasets
  lifecycle { destroy = false }
}
```
(+ the versioning resource). Plan: "will no longer be managed by Terraform". The data team then
adds an `import` block on their side.

**Interview notes**
* `removed` (1.7+) is the reviewable `terraform state rm`. With `destroy = true` it documents an
  intentional delete.
* Hand-overs need both halves in sequence: remove here (destroy = false), import there. In between
  nobody manages it - keep that window short.
* Protect stateful resources: `prevent_destroy`, deletion protection, CI policy on deletes (L14).
