d=stacks/analytics
check "bucket and versioning are in state" eval 'in_state $d aws_s3_bucket.exports && in_state $d aws_s3_bucket_versioning.exports'
check "same bucket, exports still there" eval 'same_bucket acme-analytics-exports && object_exists acme-analytics-exports 2026-10-14.csv'
check "versioning is enabled" test "$(aws s3api get-bucket-versioning --bucket acme-analytics-exports --query Status --output text)" = Enabled
check "CI plan of stacks/analytics shows no changes" plan_clean $d
verdict
