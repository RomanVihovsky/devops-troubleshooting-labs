# env_plan <env>: init a copy of the stack against that env's backend, plan with its tfvars
env_plan() {
  local c="$CI/env-$1" rc=0
  rm -rf "$c" && cp -r "$CI/stacks/logs" "$c" && rm -rf "$c/.terraform"
  terraform -chdir="$c" init -input=false -no-color -backend-config="env/$1.s3.tfbackend" >> "$VERIFY_LOG" 2>&1 || return 1
  echo "+ plan env $1" >> "$VERIFY_LOG"
  terraform -chdir="$c" plan -input=false -no-color -detailed-exitcode -var-file="env/$1.tfvars" >> "$VERIFY_LOG" 2>&1 || rc=$?
  return $rc
}
dr_applied() {
  local n pabs
  n=$(aws s3api list-buckets --query "length(Buckets[?starts_with(Name, 'acme-dr-')])" --output text)
  [ "$n" = 3 ] || return 1
  for b in $(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'acme-dr-')].Name" --output text); do
    aws s3api get-public-access-block --bucket "$b" >/dev/null 2>&1 || return 1
  done
}
prod_kept() {
  [ "$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'acme-prod-')].[Name,CreationDate]" --output text | sort)" = "$(recall prod_buckets)" ]
}
check "dr: 3 log buckets, each with a public access block" dr_applied
check "CI plan of prod shows no changes" env_plan prod
check "CI plan of dr shows no changes" env_plan dr
check "prod buckets are the originals" prod_kept
verdict
