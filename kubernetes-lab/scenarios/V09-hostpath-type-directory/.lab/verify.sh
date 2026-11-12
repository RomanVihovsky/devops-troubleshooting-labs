all_ready() { [ "$(kx -n agent get ds spool-agent -o jsonpath='{.status.desiredNumberScheduled}/{.status.numberReady}' 2>/dev/null)" = 3/3 ]; }
path_kept() { [ "$(kx -n agent get ds spool-agent -o jsonpath='{.spec.template.spec.volumes[0].hostPath.path}')" = /var/lib/spool-agent ]; }
check_eventually 120 "spool-agent Ready on all 3 workers" all_ready
check "hostPath /var/lib/spool-agent kept" path_kept
verdict
