on_workers() { ! kx -n etl get pods -l app=etl -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | grep -q k8s-cp1; }
tainted() { local n; for n in $(workers); do kx get node "$n" -o jsonpath='{.spec.taints[*].key}={.spec.taints[*].value}' | grep -q 'dedicated.*=.*batch' || return 1; done; }
check_eventually 120 "etl rollout complete, all replicas Ready" deploy_ready etl etl
check "etl runs on workers" on_workers
check "every worker still has dedicated=batch:NoSchedule" tainted
verdict
