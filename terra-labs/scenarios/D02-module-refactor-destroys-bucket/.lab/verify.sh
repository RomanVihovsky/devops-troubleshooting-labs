d=stacks/media
check "bucket, versioning and public access block live under module.uploads" \
  eval 'in_state $d module.uploads.aws_s3_bucket.this && in_state $d module.uploads.aws_s3_bucket_versioning.this && in_state $d module.uploads.aws_s3_bucket_public_access_block.this'
check "bucket not recreated, uploads still there" eval 'same_bucket acme-media-uploads && object_exists acme-media-uploads u/42/avatar.jpg'
check "CI plan of stacks/media shows no changes" plan_clean $d
verdict
