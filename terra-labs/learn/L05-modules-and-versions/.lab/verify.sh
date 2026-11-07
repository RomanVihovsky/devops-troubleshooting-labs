d=stacks/media
ctime_same() { [ "$(aws s3api list-buckets --query "Buckets[?Name=='acme-media-assets'].CreationDate" --output text)" = "$(recall ctime)" ]; }
kms() { aws s3api get-bucket-encryption --bucket acme-media-assets --output json 2>/dev/null | grep -q '"aws:kms"'; }
from_tag() {
  ci_init $d && jq -e '.Modules[] | select(.Key == "media") | .Source |
    (startswith("git::https://git.acme.example/platform/tf-module-bucket.git") and endswith("ref=v1.1.0"))' \
    "$CI/$d/.terraform/modules/modules.json" >/dev/null
}
arn_out() { ci_init $d && [ "$(ci_tf $d output -raw bucket_arn 2>/dev/null)" = arn:aws:s3:::acme-media-assets ]; }
check "state: module.media.aws_s3_bucket.this + versioning" eval 'in_state $d module.media.aws_s3_bucket.this && in_state $d module.media.aws_s3_bucket_versioning.this'
check "state: inline aws_s3_bucket.media is gone" not_in_state $d aws_s3_bucket.media
check "bucket not recreated (same creation date)" ctime_same
check "product images still there" object_exists acme-media-assets products/1001.png
check "bucket default encryption is aws:kms" kms
check "module pinned to tag v1.1.0 of tf-module-bucket" from_tag
check "output bucket_arn still works" arn_out
check "CI plan of stacks/media shows no changes" plan_clean $d
verdict
