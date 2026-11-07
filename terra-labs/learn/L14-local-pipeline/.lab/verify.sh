# run_pipe <mode> [sed-expr file]: run ci/pipeline.sh in a fresh copy of the CI checkout,
# optionally after breaking it. Prints nothing, returns the script's exit code.
run_pipe() {
  local mode=$1 expr=${2:-} file=${3:-stacks/catalog-api/main.tf} c="$CI/runs/$RANDOM" rc=0
  mkdir -p "$c" && cp -a "$CI/." "$c/" 2>/dev/null; rm -rf "$c/runs"
  if [ -n "$expr" ]; then
    if [ "$expr" = APPEND ]; then cat >> "$c/$file"; else sed -i "$expr" "$c/$file"; fi
  fi
  echo "+ pipeline.sh $mode (${expr:-clean})" >> "$VERIFY_LOG"
  (cd "$c" && timeout 300 ./ci/pipeline.sh "$mode") >> "$VERIFY_LOG" 2>&1 || rc=$?
  echo "  -> exit $rc" >> "$VERIFY_LOG"
  return $rc
}
fails() { local rc=0; run_pipe "$@" || rc=$?; [ $rc -ne 0 ] && [ $rc -ne 64 ]; }
pipe_rc() { local rc=0; run_pipe "$@" || rc=$?; echo $rc; }
bucket_intact() {
  [ "$(aws s3api list-buckets --query "Buckets[?Name=='acme-catalog-api-data'].CreationDate" --output text)" = "$(recall ctime)" ] &&
    ! bucket_exists acme-catalog-api-data-v2
}
new_param() {
  run_pipe apply APPEND <<'TF'

resource "aws_ssm_parameter" "lab_probe" {
  name           = "/catalog-api/lab-probe"
  type           = "String"
  insecure_value = "on"
}
TF
  [ "$(ssm_value /catalog-api/lab-probe)" = on ]
}
drift_cycle() {
  aws ssm put-parameter --name /catalog-api/page-size --value 500 --type String --overwrite >/dev/null
  local d; d=$(pipe_rc drift)
  aws ssm put-parameter --name /catalog-api/page-size --value 50 --type String --overwrite >/dev/null
  [ "$d" = 2 ] && [ "$(pipe_rc drift)" = 0 ]
}
check "check passes on the clean repo" run_pipe check
check "check fails on bad formatting" fails check 's/^resource "aws_s3_bucket" "catalog" {/resource "aws_s3_bucket"   "catalog"   {/'
check "check fails on a lint error (unused variable)" fails check '$a variable "unused" {\n  type = string\n}'
check "check fails when the bucket would be replaced" fails check 's/acme-catalog-api-data"/acme-catalog-api-data-v2"/'
check "check fails on an IAM policy with Action *" fails check 's/"s3:GetObject"/"*"/'
check "a failing apply changes nothing (bucket rename blocked)" eval 'fails apply "s/acme-catalog-api-data\"/acme-catalog-api-data-v2\"/" && bucket_intact'
check "drift: 2 after a manual edit, 0 once it is back" drift_cycle
check "apply ships a new resource" new_param
verdict
