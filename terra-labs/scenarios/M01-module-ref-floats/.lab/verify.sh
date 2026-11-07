d=stacks/storefront
pinned() {
  ci_init $d || return 1
  local src; src=$(jq -r '.Modules[] | select(.Key == "config") | .Source' "$CI/$d/.terraform/modules/modules.json")
  [[ $src == *"ref=v1.2.0" || $src == *"ref=$(recall v120)" ]]
}
values_kept() { [ "$(ssm_value /storefront/log_level)" = info ] && ! aws ssm get-parameter --name /storefront/tracing >/dev/null 2>&1; }
check "CI plan (fresh checkout) shows no changes" plan_clean $d
check "module pinned to v1.2.0 (tag or its commit)" pinned
check "deployed values unchanged (log_level=info, no tracing)" values_kept
verdict
