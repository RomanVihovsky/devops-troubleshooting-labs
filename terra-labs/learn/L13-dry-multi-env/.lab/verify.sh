report() {  # report <file> [extra run flags]: run --all plan in the CI checkout with a Run Report
  local out=$1; shift
  (cd "$CI/live" && terragrunt run --all --non-interactive --log-level error --no-color "$@" \
     --report-file "$out" -- plan -input=false -no-color) >> "$VERIFY_LOG" 2>&1
}
result() { jq -r --arg n "$2" '.[] | select(.Name == $n) | .Result' "$1" 2>/dev/null; }
default_report() { report "$CI/r1.json" && [ "$(result "$CI/r1.json" dev/audit)" = excluded ] && [ "$(result "$CI/r1.json" prod/audit)" = succeeded ]; }
flag_report()    { report "$CI/r2.json" --feature audit=true && [ "$(result "$CI/r2.json" dev/audit)" = succeeded ]; }
dry() {
  [ -f "$CI/live/root.hcl" ] && [ -f "$CI/live/dev/env.hcl" ] && [ -f "$CI/live/prod/env.hcl" ] &&
    ! grep -lE '^\s*(remote_state|generate)\b' "$CI"/live/*/*/terragrunt.hcl
}
untouched_values() {
  [ "$(ssm_value /dev/web/replicas)" = 1 ] && [ "$(ssm_value /prod/web/replicas)" = 3 ] &&
  [ "$(aws s3api list-buckets --query "Buckets[?Name=='acme-prod-web-assets'].CreationDate" --output text)" = "$(recall prod_ctime)" ] &&
  [ "$(aws s3api list-buckets --query "Buckets[?Name=='acme-dev-web-assets'].CreationDate" --output text)" = "$(recall dev_ctime)" ]
}
check "no remote_state/generate in unit files; root.hcl + env.hcl exist" dry
check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
check "Run Report: dev/audit excluded, prod/audit runs" default_report
check "--feature audit=true includes dev/audit" flag_report
check "nothing recreated (replicas 1/3, same buckets)" untouched_values
check "dev/audit was never deployed" test "$(aws logs describe-log-groups --log-group-name-prefix /dev/audit --query "length(logGroups)" --output text)" = 0
verdict
