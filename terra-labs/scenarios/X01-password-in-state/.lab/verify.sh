leaked=$(recall leaked)
current=$(ssm_value /orders/db/password || true)

new_not_in_state() { [ -n "$current" ] && not_in_s3_object acme-tfstate orders-db/terraform.tfstate "$current"; }
rotated()          { [ -n "$current" ] && [ "$current" != "$leaked" ] && [ ${#current} -ge 20 ]; }
secure_string()    { [ "$(aws ssm get-parameter --name /orders/db/password --query Parameter.Type --output text 2>/dev/null)" = SecureString ]; }

check "CI plan of stacks/orders-db shows no changes" plan_clean stacks/orders-db
check "leaked password is not in the current state" not_in_s3_object acme-tfstate orders-db/terraform.tfstate "$leaked"
check "the new password is not in the state either" new_not_in_state
check "password was rotated (new value, 20+ chars)" rotated
check "/orders/db/password is still a SecureString" secure_string
check "no nonsensitive() workaround in the code" not ws_has 'nonsensitive\('
verdict
