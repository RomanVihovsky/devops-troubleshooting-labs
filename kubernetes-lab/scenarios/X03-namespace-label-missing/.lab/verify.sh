kept() { [ "$(kx -n appx get networkpolicy allow-monitoring -o jsonpath='{.spec}' 2>/dev/null)" = "$(recall x03_spec)" ]; }
check_reach <<'ROWS'
monitoring - metrics-api.appx.svc:8080 open
otherx - metrics-api.appx.svc:8080 blocked
ROWS
check "the policy is unchanged" kept
verdict
