tests_pass() {
  terraform -chdir="$CI/modules/pricing" init -input=false -no-color >> "$VERIFY_LOG" 2>&1 &&
    terraform -chdir="$CI/modules/pricing" test -no-color >> "$VERIFY_LOG" 2>&1
}
check "terraform test passes in modules/pricing" tests_pass
check "tests/ unchanged" untouched modules/pricing/tests
verdict
