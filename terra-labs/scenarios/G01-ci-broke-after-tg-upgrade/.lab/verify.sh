run_ci() { (cd "$1" && timeout 300 ./ci/plan-all.sh prod) > "$CI/ci.out" 2>&1; local rc=$?; cat "$CI/ci.out" >> "$VERIFY_LOG"; return $rc; }
plans_all() { run_ci "$CI" && [ "$(grep -c 'No changes' "$CI/ci.out")" -ge 2 ]; }
fails_on_error() {
  local c="$CI/broken"; rm -rf "$c"; mkdir -p "$c"; cp -a "$CI/ci" "$CI/live" "$CI/modules" "$c/"
  find "$c" -name .terragrunt-cache -prune -exec rm -rf {} +
  printf 'resource "aws_sns_topic" "x" {\n  name = 42 = 1\n}\n' > "$c/modules/app/broken.tf"
  ! run_ci "$c"
}
modern() { ! grep -qE 'run-all|--terragrunt-|TERRAGRUNT_' "$CI/ci/plan-all.sh"; }
check "ci/plan-all.sh prod plans all units and exits 0" plans_all
check "it fails when a unit fails" fails_on_error
check "1.x CLI only (no run-all, --terragrunt-*, TERRAGRUNT_*)" modern
verdict
