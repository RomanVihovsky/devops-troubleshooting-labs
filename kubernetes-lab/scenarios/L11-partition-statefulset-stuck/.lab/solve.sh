kx -n inventory delete pod db-0 --force --grace-period=0 >/dev/null 2>&1 || true
ready() { [ "$(kx -n inventory get pod db-0 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 180 ready || true
