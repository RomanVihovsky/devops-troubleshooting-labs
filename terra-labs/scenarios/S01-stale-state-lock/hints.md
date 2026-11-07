## Hint 1
Read the whole error, not just the first line: it tells you **who** holds the lock, **since when**,
what **operation** it was, and the lock **ID**. Where does a backend with `use_lockfile = true` keep
that lock? Look in the state bucket: `aws s3 ls s3://acme-tfstate --recursive`.

## Hint 2
Before removing anyone's lock, convince yourself its owner is really dead: the runner is gone, the
lock is hours old, nobody else is applying right now. Then use the command Terraform ships for
exactly this, with the ID from the error message - run it from `stacks/payments` after `terraform init`.

## Hint 3
`terraform force-unlock <LOCK_ID>`. Then `terraform plan` should show no changes. `-lock=false`
is never the answer: two writers on one state can silently lose each other's changes.
