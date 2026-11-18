# B02: K10 (tab in the scheduler manifest) + K04 (controller-manager kubeconfig renamed) + L05 on w3 (kubelet port)
# the node first: NotReady is set by the controller-manager's node lifecycle controller - once it's down, no node
# can change state any more
nx k8s-w3 "sed -i 's|server: https://k8s-api.lab:6443|server: https://k8s-api.lab:6444|' /etc/kubernetes/kubelet.conf && systemctl restart kubelet" </dev/null
w3_down() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 180 w3_down || die "k8s-w3 stayed Ready"
nxi "$CP" >/dev/null <<'__X__'
set -eu
f=/etc/kubernetes/manifests/kube-scheduler.yaml
cp "$f" /var/tmp/kube-scheduler.yaml
python3 - <<'PY'
p = "/var/tmp/kube-scheduler.yaml"; lines = open(p).read().split("\n")
i = next(n for n, l in enumerate(lines) if l.strip().startswith("- --leader-elect"))
lines.insert(i + 1, "\t- --v=4")
open(p, "w").write("\n".join(lines))
PY
mv /var/tmp/kube-scheduler.yaml "$f"
sed -i 's|--kubeconfig=/etc/kubernetes/controller-manager.conf|--kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig|' /etc/kubernetes/manifests/kube-controller-manager.yaml
grep -q kube-controller-manager.kubeconfig /etc/kubernetes/manifests/kube-controller-manager.yaml
__X__
sched_gone() { ! kx -n kube-system get pod "kube-scheduler-$CP" >/dev/null 2>&1; }
kcm_down() { [ "$(kx -n kube-system get pod "kube-controller-manager-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" != True ]; }
retry 180 sched_gone || die "the scheduler is still there"
retry 180 kcm_down || die "the controller-manager kept running"
kns ops
kx -n ops create deployment reports --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
