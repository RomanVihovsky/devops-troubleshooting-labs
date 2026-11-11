nx k8s-w1 'systemctl enable --now chrony >/dev/null 2>&1; sleep 3; chronyc -a makestep >/dev/null; timeout 30 chronyc waitsync 25 1 0 1 >/dev/null' </dev/null || true
ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
retry 180 ready || true
