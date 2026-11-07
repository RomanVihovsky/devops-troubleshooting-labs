policy_ok() {
  local doc
  doc=$(aws iam get-role-policy --role-name prod-app --policy-name uploads --query PolicyDocument --output json)
  grep -q 'arn:aws:s3:::acme-prod-uploads/\*' <<<"$doc" && ! grep -q mock <<<"$doc"
}
# A brand-new environment, copied from prod in the CI checkout: apply `app` while `storage` has
# never been applied. Mocks must be refused - the apply has to fail and deploy nothing.
fresh_env_refuses_mocks() {
  local env="zzfresh$RANDOM"     # unique per run: earlier probes may have left resources behind
  cp -r "$CI/live/prod" "$CI/live/$env"
  find "$CI/live/$env" -name .terragrunt-cache -prune -exec rm -rf {} +   # no state from prod
  sed -i "s/env *= *\"prod\"/env = \"$env\"/" "$CI/live/$env/env.hcl"
  if (cd "$CI/live/$env/app" && terragrunt --non-interactive --log-level error apply -auto-approve \
        -input=false -no-color) >> "$VERIFY_LOG" 2>&1; then
    return 1
  fi
  ! aws ssm get-parameter --name "/$env/app/uploads-bucket" >/dev/null 2>&1
}

check "SSM /prod/app/uploads-bucket = acme-prod-uploads" test "$(ssm_value /prod/app/uploads-bucket)" = acme-prod-uploads
check "prod-app role may write only to acme-prod-uploads" policy_ok
check "terragrunt run --all plan in live/prod: no changes" tg_plan_clean live/prod
check "uploads bucket kept its files (not recreated)" object_exists acme-prod-uploads avatars/42.png
check "a brand-new env refuses to apply app with mock outputs" fresh_env_refuses_mocks
verdict
