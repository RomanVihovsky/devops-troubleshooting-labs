d=stacks/platform-shared
check "datasets bucket + versioning no longer in this state" eval 'not_in_state $d aws_s3_bucket.datasets && not_in_state $d aws_s3_bucket_versioning.datasets'
check "bucket still exists with its files (same bucket)" eval 'same_bucket acme-ml-datasets && object_exists acme-ml-datasets v3/train.csv'
check "versioning still enabled" test "$(aws s3api get-bucket-versioning --bucket acme-ml-datasets --query Status --output text)" = Enabled
check "CI plan of stacks/platform-shared shows no changes" plan_clean $d
verdict
