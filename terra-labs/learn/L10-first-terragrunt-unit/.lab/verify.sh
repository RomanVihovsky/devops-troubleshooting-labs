b=acme-tg-state
versioned() { [ "$(aws s3api get-bucket-versioning --bucket $b --query Status --output text 2>/dev/null)" = Enabled ]; }
settings()  {
  [ "$(ssm_value /dev/web/log_level)" = debug ] && [ "$(ssm_value /dev/web/feature_x)" = on ]
}
tagged_dev() { aws s3api get-bucket-tagging --bucket acme-dev-web-assets --output json 2>/dev/null | jq -e '.TagSet[] | select(.Key == "env" and .Value == "dev")' >/dev/null; }
fmt_ok() { (cd "$CI/live" && terragrunt hcl fmt --check --log-level error) >> "$VERIFY_LOG" 2>&1; }
check "state bucket acme-tg-state exists and is versioned" versioned
check "state at s3://acme-tg-state/dev/web/terraform.tfstate" object_exists $b dev/web/terraform.tfstate
check "SSM /dev/web/log_level=debug, /dev/web/feature_x=on" settings
check "assets bucket exists, tagged env=dev (default_tags)" tagged_dev
check "root config is live/root.hcl (no root terragrunt.hcl)" eval '[ -f "$CI/live/root.hcl" ] && [ ! -f "$CI/live/terragrunt.hcl" ]'
check "the module has no provider block (Terragrunt generates it)" not grep -qE '^\s*provider\s+"aws"' "$CI"/modules/web-config/*.tf
check "terragrunt hcl fmt --check passes in live/" fmt_ok
check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
verdict
