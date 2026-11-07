check "/dev/checkout/prefix = acme-dev-checkout" test "$(ssm_value /dev/checkout/prefix)" = acme-dev-checkout
check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
check "modules/app still uses ../shared/names" untouched modules
verdict
