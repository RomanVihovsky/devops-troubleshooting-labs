d=stacks/events
v2() {
  ci_init $d && jq -e '[.Modules[] | select(.Key == "orders" or .Key == "refunds") | .Source
     | capture("ref=v(?<maj>[0-9]+)") | .maj | tonumber >= 2] | length == 2 and all' \
     "$CI/$d/.terraform/modules/modules.json" >/dev/null
}
encrypted_and_subscribed() {
  local t arn k
  for t in orders refunds; do
    arn=$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':$t-events')].TopicArn | [0]" --output text)
    k=$(aws sns get-topic-attributes --topic-arn "$arn" --query Attributes.KmsMasterKeyId --output text 2>/dev/null)
    [ -n "$k" ] && [ "$k" != None ] || return 1
    [ "$(aws sns list-subscriptions-by-topic --topic-arn "$arn" --query 'length(Subscriptions)' --output text)" = 1 ] || return 1
  done
}
check "CI init + plan: no changes" plan_clean $d
check "both modules from tf-module-topic >= v2.0.0" v2
check "topics KMS-encrypted, subscriptions survived" encrypted_and_subscribed
verdict
