hpa_ok() { kx -n api get hpa -o json | jq -e '[.items[] | select(.spec.scaleTargetRef.name == "api" and .spec.minReplicas <= 2 and .spec.maxReplicas >= 10)] | length == 1' >/dev/null; }
at2_for() {
  local t=$1; [ -n "${LAB_EXPECT_FAIL:-}" ] && t=3
  deploy_ready api api 2 || return 1
  sleep "$t"; deploy_ready api api 2
}
check "an HPA scales api with minReplicas <= 2, maxReplicas >= 10" hpa_ok
check_eventually 420 "api runs 2 Ready pods and stays at 2 for 60 s" at2_for 60
verdict
