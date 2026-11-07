count_in() { aws ssm get-parameters-by-path --region "$1" --path /prod/notifier --query 'length(Parameters)' --output text 2>/dev/null; }
check "settings exist in eu-central-1" test "$(count_in eu-central-1)" = 2
check "nothing left in us-east-1" test "$(count_in us-east-1)" = 0
check "modules/notifier configures no provider" not grep -rqE '^\s*provider\s+"aws"' "$CI/modules/notifier"
check "root.hcl no longer skips the generated provider" not grep -qE 'if_exists\s*=\s*"skip"' "$CI/live/root.hcl"
check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
verdict
