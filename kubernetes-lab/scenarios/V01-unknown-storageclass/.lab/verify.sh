bound() { [ "$(kx -n uploads get pvc uploads-data -o jsonpath='{.status.phase}' 2>/dev/null)" = Bound ]; }
check_eventually 120 "PVC uploads-data Bound" bound
check_eventually 120 "uploads runs" deploy_ready uploads uploads
verdict
