nx k8s-w2 'systemctl disable --now audit-spooler' </dev/null >/dev/null 2>&1
off() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}')" = False ]; }
retry 360 off || true
