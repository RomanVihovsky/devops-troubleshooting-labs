gone() { ! kx -n maint get pod "$1" >/dev/null 2>&1; }
schedulable() { [ "$(kx get node k8s-w2 -o jsonpath='{.spec.unschedulable}')" != true ]; }
agents() { [ "$(kx -n maint get ds node-agent -o jsonpath='{.status.numberReady}')" -ge 3 ]; }
check "the cache pod that ran on k8s-w2 is gone" gone "$(recall o07_cache)"
check "the scratch pod is gone" gone scratch
check "k8s-w2 is schedulable again" schedulable
check_eventually 120 "cache: 2 Ready pods" deploy_ready maint cache 2
check_eventually 60 "node-agent on every worker" agents
verdict
