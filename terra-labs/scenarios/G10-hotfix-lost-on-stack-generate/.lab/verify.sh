stack_plan_clean() {
  (cd "$CI/live/prod" && terragrunt stack run --non-interactive --log-level error --no-color -- \
     plan -detailed-exitcode -input=false -no-color -lock-timeout="${LAB_LOCK_TIMEOUT:-10s}") >> "$VERIFY_LOG" 2>&1
}
check "/prod/web/replicas = 4" test "$(ssm_value /prod/web/replicas)" = 4
check "fresh checkout: terragrunt stack run -- plan shows no changes" stack_plan_clean
check ".terragrunt-stack/ is not committed" not eval 'git -C "$WS" ls-files | grep -q "\.terragrunt-stack/"'
verdict
