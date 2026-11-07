# One CI workspace across both stages (like a runner keeping artifacts).
c="$CI/runner"
rm -rf "$c" && mkdir -p "$c" && cp -a "$CI/." "$c/" 2>/dev/null; rm -rf "$c/runner"
add_param() { printf '\nresource "aws_ssm_parameter" "%s" {\n  name           = "/catalog/%s"\n  type           = "String"\n  insecure_value = "on"\n}\n' "$1" "$1" >> "$c/stacks/catalog/main.tf"; }
pipe() { (cd "$c" && timeout 300 ./ci/pipeline.sh "$1") >> "$VERIFY_LOG" 2>&1; }
reviewed_only() {
  add_param lab_reviewed_a          # MR A
  pipe plan || return 1
  add_param lab_unreviewed_b        # MR B lands after the review
  pipe apply || return 1
  aws ssm get-parameter --name /catalog/lab_reviewed_a >/dev/null 2>&1 &&
    ! aws ssm get-parameter --name /catalog/lab_unreviewed_b >/dev/null 2>&1
}
no_plan_no_apply() {
  local f="$CI/fresh"; rm -rf "$f" && mkdir -p "$f" && cp -a "$CI/ci" "$CI/stacks" "$f/" && rm -rf "$f/stacks/catalog/.terraform"
  printf '\nresource "aws_ssm_parameter" "lab_sneaky" {\n  name           = "/catalog/lab_sneaky"\n  type           = "String"\n  insecure_value = "on"\n}\n' >> "$f/stacks/catalog/main.tf"
  ! (cd "$f" && timeout 300 ./ci/pipeline.sh apply) >> "$VERIFY_LOG" 2>&1 &&
    ! aws ssm get-parameter --name /catalog/lab_sneaky >/dev/null 2>&1
}
check "apply ships exactly the reviewed change (not the later commit)" reviewed_only
check "apply without a reviewed plan fails and changes nothing" no_plan_no_apply
verdict
