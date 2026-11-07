CI_INIT_ARGS[inventory]="-backend-config=backend.hcl"
b=acme-tfstate
versioned() { [ "$(aws s3api get-bucket-versioning --bucket $b --query Status --output text 2>/dev/null)" = Enabled ]; }
encrypted() { aws s3api get-bucket-encryption --bucket $b --output json 2>/dev/null | grep -q '"aws:kms"'; }
private()   {
  [ "$(aws s3api get-public-access-block --bucket $b --output json 2>/dev/null |
       jq '[.PublicAccessBlockConfiguration[]] | all')" = true ]
}
in_s3() { s3_cat $b inventory/terraform.tfstate | jq -e '[.resources[].type] | index("aws_s3_bucket")' >/dev/null; }
not_recreated() {
  [ "$(aws s3api list-buckets --query "Buckets[?Name=='acme-inventory-exports'].CreationDate" --output text)" = "$(recall bucket_ctime)" ] &&
  [ "$(aws ssm get-parameters-by-path --path /inventory/warehouses --query 'sort_by(Parameters,&Name)[].LastModifiedDate' --output text)" = "$(recall params_mtime)" ]
}
backend_ok() {
  ci_init inventory &&
    jq -e '.backend.type == "s3" and .backend.config.use_lockfile == true and (.backend.config.dynamodb_table // "") == ""' \
      "$CI/inventory/.terraform/terraform.tfstate" >/dev/null
}
check "acme-tfstate: versioning enabled" versioned
check "acme-tfstate: default encryption aws:kms" encrypted
check "acme-tfstate: all public access blocked" private
check "inventory state is in s3://acme-tfstate/inventory/terraform.tfstate" in_s3
check "nothing was recreated (bucket and parameters untouched)" not_recreated
check "no local state left in inventory/" not eval 'ls "$WS"/inventory/terraform.tfstate* >/dev/null 2>&1'
check "backend: s3 + use_lockfile, no DynamoDB" backend_ok
check "inventory resources still in state" in_state inventory aws_s3_bucket.exports
check "CI plan of inventory/ shows no changes" plan_clean inventory
verdict
