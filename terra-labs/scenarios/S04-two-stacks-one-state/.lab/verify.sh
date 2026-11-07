key_of() { ci_init "$1" && jq -r .backend.config.key "$CI/$1/.terraform/terraform.tfstate"; }
search_untouched() {
  [ "$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':search-index-updates')].TopicArn | [0]" --output text)" = "$(recall search_topic)" ] &&
  [ "$(aws ssm get-parameter --name /search/index --query Parameter.LastModifiedDate --output text)" = "$(recall search_param)" ]
}
recs_live() {
  [ "$(ssm_value /recs/model)" = als-2026-10 ] &&
  [ "$(aws sns list-topics --query "length(Topics[?ends_with(TopicArn, ':recs-model-updates')])" --output text)" = 1 ]
}
check "CI plan of stacks/search shows no changes" plan_clean stacks/search
check "CI plan of stacks/recs shows no changes" plan_clean stacks/recs
check "separate states (different keys)" eval '[ -n "$(key_of stacks/recs)" ] && [ "$(key_of stacks/recs)" != "$(key_of stacks/search)" ]'
check "search topic and parameters untouched" search_untouched
check "recs parameters and topic exist" recs_live
verdict
