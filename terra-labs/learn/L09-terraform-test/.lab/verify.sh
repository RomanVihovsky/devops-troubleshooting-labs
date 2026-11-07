tf_test() {   # tf_test <module dir under $CI> [-filter=...]: init + terraform test
  local m=$1; shift
  terraform -chdir="$m" init -input=false -no-color >> "$VERIFY_LOG" 2>&1 &&
    terraform -chdir="$m" test -no-color "$@" >> "$VERIFY_LOG" 2>&1
}
# mutant <module> <file> <sed expr> [test args]: copy the module, break it, its tests must FAIL
mutant() {
  local src=$CI/modules/$1 m="$CI/mutants/$1-$RANDOM"; shift
  local file=$1 expr=$2; shift 2
  mkdir -p "$(dirname "$m")" && cp -r "$src" "$m" && rm -rf "$m/.terraform"
  sed -i "$expr" "$m/$file"
  ! cmp -s "$src/$file" "$m/$file" || return 1      # the mutation must actually change something
  echo "+ mutant $m: $expr" >> "$VERIFY_LOG"
  ! tf_test "$m" "$@"
}
runs()    { cat "$CI"/modules/*/tests/*.tftest.hcl 2>/dev/null | grep -cE '^\s*run\s+"'; }
has()     { cat "$CI"/modules/*/tests/*.tftest.hcl 2>/dev/null | grep -qE "$1"; }

check "terraform test passes in modules/naming" tf_test "$CI/modules/naming"
check "terraform test passes in modules/bucket (unit + integration)" tf_test "$CI/modules/bucket"
check "tests use expect_failures, mock_provider and a command = apply run" \
  eval 'has expect_failures && has mock_provider && has "command *= *apply" && [ "$(runs)" -ge 3 ]'
check "mutant: '_' instead of '-' in names -> naming tests fail" mutant naming main.tf 's/join("-"/join("_"/'
check "mutant: env validation dropped -> naming tests fail" mutant naming main.tf 's/contains(\["dev", "staging", "prod"\], var.env)/true/'
check "mutant: versioning Suspended -> integration test fails" mutant bucket main.tf 's/status = "Enabled"/status = "Suspended"/' -filter=tests/integration.tftest.hcl
check "mutant: arn output broken -> unit test fails" mutant bucket main.tf 's/value = aws_s3_bucket.this.arn/value = aws_s3_bucket.this.id/' -filter=tests/unit.tftest.hcl
verdict
