# tf-module-topic

## v2.0.0 - BREAKING
- requires AWS provider >= 6.0
- input `name` renamed to `topic_name` (upgrade: rename the argument; resources are not replaced)

## v1.4.0
- server-side encryption with KMS (`kms_key_id`, default `alias/aws/sns`)
- pin the AWS provider to `~> 5.0`

## v1.3.0
- output `arn`
