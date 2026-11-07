from_env() {
  [ "$(cd "$CI/live/staging/web" && terragrunt render --json --log-level error 2>>"$VERIFY_LOG" | jq -r .inputs.replicas)" = 3 ] &&
    grep -qE 'replicas\s*=\s*local\.' "$CI/live/staging/web/terragrunt.hcl"
}
check "/staging/web/replicas = 3" test "$(ssm_value /staging/web/replicas)" = 3
check "the value comes from env.hcl (render shows inputs.replicas = 3)" from_env
check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
verdict
