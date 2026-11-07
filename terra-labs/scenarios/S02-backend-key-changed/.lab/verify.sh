d=stacks/billing
key_new() { ci_init $d && jq -e '.backend.config.key == "prod/billing/terraform.tfstate"' "$CI/$d/.terraform/terraform.tfstate" >/dev/null; }
params_v1() { [ "$(aws ssm get-parameters-by-path --path /billing/currencies --query 'Parameters[?Version!=`1`] | length(@)' --output text)" = 0 ]; }
check "CI plan with key prod/billing/terraform.tfstate shows no changes" eval 'key_new && plan_clean $d'
check "old key billing/terraform.tfstate is gone" not object_exists acme-tfstate billing/terraform.tfstate
check "export bucket not recreated, invoices still there" eval 'same_bucket acme-billing-exports && object_exists acme-billing-exports 2026/10/invoices.csv'
check "no duplicates: still one SNS topic, parameters never rewritten" eval '[ "$(aws sns list-topics --query "length(Topics)" --output text)" = "$(recall topics)" ] && params_v1'
verdict
