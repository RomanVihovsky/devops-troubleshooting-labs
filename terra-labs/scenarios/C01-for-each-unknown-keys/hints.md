## Hint 1
Plan prod and dr and compare. Keys of `for_each` must be known at **plan** time. In prod the bucket names
are already in state; in a new env they contain a `random_id` that does not exist yet.

## Hint 2
Key by something static you already know: the purposes in `var.log_buckets` ("access", "audit", "app").
The bucket for a purpose is `aws_s3_bucket.logs[index(var.log_buckets, each.key)]`.

## Hint 3
Changing the keys changes prod's addresses (`...logs["acme-prod-access-logs-<hex>"]` -> `...logs["access"]`)
-> add `moved` blocks for prod's three access blocks (`terraform state list` shows the old keys). In dr
they are no-ops. Plan prod (clean), then init/apply dr.
