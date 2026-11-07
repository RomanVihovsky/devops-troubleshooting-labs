d=stacks/web-config
staging_back() {
  [ "$(ssm_value /staging/web/log_level)" = info ] &&
  [ "$(aws sns list-topics --query "length(Topics[?ends_with(TopicArn, ':staging-web-events')])" --output text)" = 1 ]
}
no_prod() {
  [ "$(aws sns list-topics --query "length(Topics[?contains(TopicArn, ':prod-')])" --output text)" = 0 ] &&
  [ "$(aws ssm get-parameters-by-path --path /prod --recursive --query 'length(Parameters)' --output text)" = 0 ]
}
no_override() { ! ls "$CI/$d"/*.auto.tfvars* >/dev/null 2>&1 || ! grep -qE '^\s*env\s*=' "$CI/$d"/*.auto.tfvars*; }
check "staging parameters and topic are back" staging_back
check "no prod-* resources in this account" no_prod
check "no *.auto.tfvars overriding env" no_override
check "CI plan of stacks/web-config shows no changes" plan_clean $d
verdict
