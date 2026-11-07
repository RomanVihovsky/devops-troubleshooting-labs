CI_PLAN_ARGS[app-config]="-var-file=env/staging.tfvars"
d=app-config
# plan_with <tfvars-ish args...>: does a CI plan accept these inputs?
plan_with() { ci_init "$d" && ci_tf "$d" plan -input=false -no-color -refresh=false "$@" >> "$VERIFY_LOG" 2>&1; }
svc() { echo "service={name=\"${1}\",port=${2},replicas=${3}}"; }
cfg="$WS/app-config/out/staging-checkout.json"

check "config file got the defaults (port 8080, 2 replicas)" \
  test "$(jq -c '[.port, .replicas, .tags.env]' "$cfg" 2>/dev/null)" = '[8080,2,"staging"]'
check "token file holds the token" test "$(cat "$WS/app-config/out/staging-checkout.token" 2>/dev/null)" = "$(recall token)"
check "valid staging inputs plan fine" plan_with -var-file=env/staging.tfvars
check "env=qa is rejected" not plan_with -var-file=env/staging.tfvars -var env=qa
check "service name Checkout_Svc is rejected" not plan_with -var-file=env/staging.tfvars -var "$(svc Checkout_Svc 8080 2)"
check "port 80 is rejected" not plan_with -var-file=env/staging.tfvars -var "$(svc checkout 80 2)"
check "prod with 1 replica is rejected" not plan_with -var-file=env/prod.tfvars -var "$(svc checkout 8080 1)"
check "prod with 3 replicas is accepted" plan_with -var-file=env/prod.tfvars
check "api_token is required (no default)" not env -u TF_VAR_api_token bash -c "$(declare -f ci_tf); CI='$CI'; ci_tf $d plan -input=false -no-color -refresh=false -var-file=env/staging.tfvars"
check "CI plan with staging.tfvars shows no changes" plan_clean app-config
verdict
