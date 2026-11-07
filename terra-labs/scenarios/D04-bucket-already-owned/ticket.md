# Apply fails: BucketAlreadyOwnedByYou (acme-analytics-exports)
**INFRA-177** · P2 · Reporter: analytics team

We finally put the exports bucket into code (`stacks/analytics/exports.tf`), but `terraform apply`
fails with `BucketAlreadyOwnedByYou`. Background: during an outage last month someone created
`acme-analytics-exports` by hand so the export jobs could keep running. It holds the exports since.

Bring the existing bucket under Terraform. Don't delete or recreate it.

**Test**: the bucket and its versioning are in state; it is the same bucket with its files; versioning is
on; a CI plan shows no changes.
