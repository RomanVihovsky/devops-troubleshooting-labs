on_13() { [ "$(kx -n pay get pods -l app=checkout --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | sort -u)" = registry.lab:5000/lab/labapp:1.3 ]; }
items_ok() {
  local p n=0
  for p in $(kx -n pay get pods -l app=checkout --field-selector=status.phase=Running -o name); do
    kx -n pay exec "$p" -- labapp get http://localhost:8080/items >/dev/null 2>&1 || return 1; n=$((n + 1))
  done
  [ $n -ge 3 ]
}
history() { [ "$(kx -n pay get deploy checkout -o jsonpath='{.spec.revisionHistoryLimit}')" -ge 2 ]; }
check_eventually 150 "checkout: 3 Ready pods" deploy_ready pay checkout 3
check_eventually 60 "all on labapp:1.3" on_13
check_eventually 60 "/items answers 200 in every pod" items_ok
check "revisionHistoryLimit >= 2" history
verdict
