# K04: --kubeconfig points at a renamed file that doesn't exist (and isn't mounted)
nx "$CP" "sed -i 's|--kubeconfig=/etc/kubernetes/controller-manager.conf|--kubeconfig=/etc/kubernetes/controller-manager.kubeconfig|' /etc/kubernetes/manifests/kube-controller-manager.yaml && grep -q controller-manager.kubeconfig /etc/kubernetes/manifests/kube-controller-manager.yaml" </dev/null
notready() { [ "$(kx -n kube-system get pod "kube-controller-manager-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" != True ]; }
retry 180 notready || die "the controller-manager kept running"
kns ops
kx -n ops create deployment web --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
sleep 10
[ -z "$(kx -n ops get rs -o name)" ] || die "a ReplicaSet appeared - the controller-manager still works"
