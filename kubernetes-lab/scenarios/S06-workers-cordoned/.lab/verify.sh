none_cordoned() { [ -z "$(kx get nodes -o jsonpath='{range .items[?(@.spec.unschedulable==true)]}{.metadata.name}{end}')" ]; }
check_eventually 120 "notify rollout complete, Ready" deploy_ready notify notify
check "no node cordoned" none_cordoned
verdict
