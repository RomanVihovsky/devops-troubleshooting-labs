on_worker() { case $(kx -n legacy get pods -l app=legacy-sync --field-selector=status.phase=Running -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null) in k8s-w1|k8s-w2|k8s-w3) return 0 ;; esac; return 1; }
check_eventually 120 "legacy-sync rollout complete, Ready" deploy_ready legacy legacy-sync
check "it runs on a worker of this cluster" on_worker
verdict
