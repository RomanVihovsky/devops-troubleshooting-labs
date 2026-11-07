## Hint 1
The error is honest: the bucket exists and your account owns it. Terraform only knows what is in its
state - and creating something that already exists is not an option for S3 names.

## Hint 2
Adopt it with an `import` block (`to` = the resource address, `id` = the bucket name), then plan:
it should say import for the bucket and create only for things that really don't exist yet.

## Hint 3
`import { to = aws_s3_bucket.exports  id = "acme-analytics-exports" }`, `terraform apply`, then
`terraform plan` -> no changes. Keep or delete the import block afterwards - it's a no-op once imported.
