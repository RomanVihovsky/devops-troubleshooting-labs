for r in aws_s3_bucket aws_s3_bucket_versioning aws_s3_bucket_public_access_block; do
  printf '\nmoved {\n  from = %s.uploads\n  to   = module.uploads.%s.this\n}\n' "$r" "$r" >> stacks/media/main.tf
done
apply stacks/media
