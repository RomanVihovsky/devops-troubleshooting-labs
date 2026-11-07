outs() { s3_cat acme-tfstate network/terraform.tfstate | jq -r '.outputs'; }
both_outputs() {
  local o; o=$(outs)
  [ "$(jq -r '.app_subnet_id.value' <<<"$o")" != null ] && [ "$(jq -r '.subnet_id.value' <<<"$o")" = "$(jq -r '.app_subnet_id.value' <<<"$o")" ]
}
marked() {
  awk '/^output "subnet_id"/,/^}/' "$CI/stacks/network/"*.tf | grep -qiE 'deprecat'
}
check "CI plan of stacks/network shows no changes" plan_clean stacks/network
check "CI plan of stacks/payments-api shows no changes" plan_clean stacks/payments-api
check "network state exposes app_subnet_id and subnet_id (same value)" both_outputs
check "stacks/payments-api unchanged" untouched stacks/payments-api
check "the old output is marked deprecated" marked
verdict
