## Hint 1
`aws s3api get-bucket-location --bucket acme-media-replica`. Which provider configuration does
`module "replica"` use? Without instructions a module inherits the **default** provider.

## Hint 2
Pass providers into a module explicitly: `providers = { aws = aws.dr }`. The module can declare that it
expects one with `configuration_aliases` - not needed here, its only provider is `aws`.

## Hint 3
Add the `providers` map and plan: probably **no changes** - the provider finds the existing bucket and is
happy. Wiring decides where *new* things go; it does not move existing ones. Recreate the (empty) replica:
`terraform apply -replace=module.replica.aws_s3_bucket.this -replace=module.replica.aws_s3_bucket_versioning.this`.
