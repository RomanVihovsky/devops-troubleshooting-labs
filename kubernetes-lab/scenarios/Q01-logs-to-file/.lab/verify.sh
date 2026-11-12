marker="q01-$RANDOM$RANDOM"
in_logs() {
  http_code billing2 "http://invoicer.billing2.svc:8080/items?probe=$marker" >/dev/null
  sleep 3
  kx -n billing2 logs -l app=invoicer --all-containers --tail=200 2>/dev/null | grep -q "$marker"
}
file_kept() {
  kx -n billing2 get deploy invoicer -o json | jq -e '[.spec.template.spec.containers[].env[]? | select(.name == "LOG_FILE" and .value == "/var/log/labapp/app.log")] | length == 1' >/dev/null \
    && kx -n billing2 exec deploy/invoicer -c invoicer -- sh -c 'test -s /var/log/labapp/app.log' 2>/dev/null
}
check_eventually 120 "invoicer: 1 Ready pod" deploy_ready billing2 invoicer 1
check_eventually 60 "a request the test sends appears in kubectl logs" in_logs
check "invoicer still writes /var/log/labapp/app.log" file_kept
verdict
