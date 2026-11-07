b=acme-tg-state-staging
standard() {
  [ "$(aws s3api get-bucket-versioning --bucket $b --query Status --output text 2>/dev/null)" = Enabled ] &&
  aws s3api get-bucket-encryption --bucket $b >/dev/null 2>&1 &&
  [ "$(aws s3api get-public-access-block --bucket $b --output json 2>/dev/null | jq '[.PublicAccessBlockConfiguration[]] | all')" = true ]
}
check "acme-tg-state-staging: versioned, encrypted, private" standard
check "staging network deployed (state in its bucket)" object_exists $b staging/network/terraform.tfstate
check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
verdict
