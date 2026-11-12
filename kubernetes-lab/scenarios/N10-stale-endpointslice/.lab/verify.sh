db_ok() { pods_get legacy app=orders /ready | jq -se 'length >= 2 and all(.[]; .checks.postgres == "ok")' >/dev/null 2>&1; }
to_new() {
  local ip; ip=$(kx -n legacy get pods -l app=pg-new -o jsonpath='{.items[0].status.podIP}')
  [ -n "$ip" ] && [ "$(kx -n legacy get endpointslices -l kubernetes.io/service-name=db -o jsonpath='{.items[*].endpoints[*].addresses[*]}' | tr ' ' '\n' | sort -u)" = "$ip" ]
}
same_url() { kx -n legacy get deploy orders -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DATABASE_URL")].value}' | grep -q '@db:5432/'; }
old_off() { [ "$(kx -n legacy get deploy pg-old -o jsonpath='{.spec.replicas}')" = 0 ]; }
check_eventually 150 "orders: 2 Ready pods" deploy_ready legacy orders 2
check_eventually 60 "both connect to the database" db_ok
check "Service db leads to pg-new's pod (only)" to_new
check "orders still uses db:5432" same_url
check "the old database stays off" old_off
verdict
