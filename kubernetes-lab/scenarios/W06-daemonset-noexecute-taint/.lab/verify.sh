on_workers() { [ "$(kx -n logging get pods -l app=log-agent --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort -u | tr '\n' ' ')" = "k8s-w1 k8s-w2 k8s-w3 " ] \
               && [ "$(kx -n logging get ds log-agent -o jsonpath='{.status.numberReady}')" -ge 3 ]; }
tainted() { for n in k8s-w1 k8s-w2; do kx get node "$n" -o jsonpath='{.spec.taints[*].key}' | grep -qw maintenance || return 1; done; }
check_eventually 120 "log-agent Ready on k8s-w1, k8s-w2 and k8s-w3" on_workers
check "the maintenance taints are still on k8s-w1 and k8s-w2" tainted
verdict
