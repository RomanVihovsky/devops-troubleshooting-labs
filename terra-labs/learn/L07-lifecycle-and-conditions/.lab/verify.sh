d=shop
plan_log() { ci_init $d && ci_tf $d plan -input=false -no-color "$@" > "$CI/plan.out" 2>&1; local rc=$?; cat "$CI/plan.out" >> "$VERIFY_LOG"; return $rc; }
destroy_refused() { ! plan_log -destroy && grep -q 'prevent_destroy' "$CI/plan.out"; }
replaces_only_container() {
  plan_log -var config_version=99 &&
    grep -qE 'docker_container.web (must|will) be replaced' "$CI/plan.out" &&
    ! grep -q 'docker_volume.data must be replaced' "$CI/plan.out"
}
port_precondition() { ! plan_log -var public_port=8080 && grep -q 'Resource precondition failed' "$CI/plan.out"; }
check_passes() {
  ci_init $d && ci_tf $d plan -input=false -no-color -out=check.tfplan >> "$VERIFY_LOG" 2>&1 &&
    ci_tf $d show -json check.tfplan | jq -e '[.checks[]? | select(.address.kind == "check") | .status] | length > 0 and all(. == "pass")' >/dev/null
}
replaced_for_v2() { ! same_ctr tfl-shop-web && ctr_running tfl-shop-web && grep -qE '^config_version *= *2' "$WS/shop/terraform.tfvars"; }
volume_survived() { [ "$(docker volume inspect -f '{{.CreatedAt}}' tfl-shop-data 2>/dev/null)" = "$(recall vol_created)" ]; }

check "terraform plan -destroy is refused (prevent_destroy)" destroy_refused
check "banner still says marketing's text" test "$(ssm_value /shop/banner)" = "Black Friday -20%"
check "CI plan shows no changes (banner edit ignored)" plan_clean $d
check "a config_version change replaces the container, not the volume" replaces_only_container
check "public_port = 8080 fails a precondition" port_precondition
check "health check block exists and passes" check_passes
check "container replaced for config_version 2" replaced_for_v2
check "data volume survived" volume_survived
verdict
