nx "$CP" "sed -i 's|/kube-schedular:|/kube-scheduler:|' /etc/kubernetes/manifests/kube-scheduler.yaml" </dev/null
ready() { [ "$(kx -n kube-system get pod "kube-scheduler-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 180 ready || true
