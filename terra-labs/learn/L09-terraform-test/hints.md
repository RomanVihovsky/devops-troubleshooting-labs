## Hint 1
```
run "staging_names" {
  command = plan
  variables { env = "staging"  team = "payments"  name = "invoices" }
  assert {
    condition     = output.bucket_name == "acme-staging-payments-invoices"
    error_message = "unexpected bucket name ${output.bucket_name}"
  }
}
```
A failing validation is a *pass* when you list it: `expect_failures = [var.env]`.

## Hint 2
```
mock_provider "aws" {}
override_resource {
  target = aws_s3_bucket.this
  values = { arn = "arn:aws:s3:::unit-bucket" }
}
```
Top-level `override_resource` applies to every run in the file; `command = apply` is fine with a
mock provider - nothing leaves your machine.

## Hint 3
Integration: no mock, `command = apply`, then assert on a resource attribute:
`aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"`.
`terraform test -verbose` prints plans/state per run.
