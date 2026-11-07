d=stacks/media-dr
loc() { aws s3api get-bucket-location --bucket "$1" --query LocationConstraint --output text 2>/dev/null; }
wired() {
  ci_init $d && ci_tf $d show -json 2>/dev/null |
    jq -e '[.values.root_module.child_modules[]?.resources[]? | select(.address == "module.replica.aws_s3_bucket.this") | .values.region] == ["eu-west-1"]' >/dev/null
}
check "acme-media-replica is in eu-west-1" test "$(loc acme-media-replica)" = eu-west-1
check "primary unchanged (same bucket, still in eu-central-1, files there)" eval 'same_bucket acme-media-primary && [ "$(loc acme-media-primary)" = eu-central-1 ] && object_exists acme-media-primary master/0001.raw'
check "module.replica is wired to the DR region" wired
check "CI plan of stacks/media-dr shows no changes" plan_clean $d
verdict
