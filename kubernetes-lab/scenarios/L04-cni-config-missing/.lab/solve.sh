kx -n kube-system delete pod -l k8s-app=calico-node --field-selector spec.nodeName=k8s-w3 >/dev/null
ready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
retry 180 ready || true
