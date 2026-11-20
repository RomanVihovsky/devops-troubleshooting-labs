nxi "$CP" >/dev/null <<'__X__'
set -eu
f=/etc/kubernetes/manifests/kube-scheduler.yaml
lead=$(grep -m1 -E '^ +- --leader-elect' "$f" | sed -E 's/^( +).*/\1/')
sed "s/^\t- --v=4/${lead}- --v=4/" "$f" > /var/tmp/kube-scheduler.yaml
mv /var/tmp/kube-scheduler.yaml "$f"
sed -i 's|--kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig|--kubeconfig=/etc/kubernetes/controller-manager.conf|' /etc/kubernetes/manifests/kube-controller-manager.yaml
__X__
nx k8s-w3 "sed -i 's|server: https://k8s-api.lab:6444|server: https://k8s-api.lab:6443|' /etc/kubernetes/kubelet.conf && systemctl restart kubelet" </dev/null
retry 180 nodes_ready || true
r() { [ "$(kx -n kube-system get pod "kube-controller-manager-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 180 r || true
