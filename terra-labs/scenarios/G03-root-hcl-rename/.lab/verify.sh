check "terragrunt run --all plan in live/: no changes" tg_plan_clean live
check "no root live/terragrunt.hcl" test ! -e "$CI/live/terragrunt.hcl"
verdict
