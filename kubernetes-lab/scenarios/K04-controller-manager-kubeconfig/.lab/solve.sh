nx "$CP" "sed -i 's|--kubeconfig=/etc/kubernetes/controller-manager.kubeconfig|--kubeconfig=/etc/kubernetes/controller-manager.conf|' /etc/kubernetes/manifests/kube-controller-manager.yaml" </dev/null
ready() { [ "$(kx -n kube-system get pod "kube-controller-manager-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 180 ready || true
