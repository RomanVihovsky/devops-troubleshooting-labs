all_14() { [ "$(kx -n blog get pods -l app=blog --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | sort -u)" = registry.lab:5000/lab/labapp:1.4 ]; }
not_paused() { [ "$(kx -n blog get deploy blog -o jsonpath='{.spec.paused}')" != true ]; }
check "the Deployment is not paused" not_paused
check_eventually 120 "blog: 3 Ready pods" deploy_ready blog blog 3
check_eventually 60 "every pod runs labapp:1.4" all_14
verdict
