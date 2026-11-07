state_bucket
apply stacks/media-dr
echo 'raw' | aws s3 cp - s3://acme-media-primary/master/0001.raw >/dev/null
remember_bucket acme-media-primary
