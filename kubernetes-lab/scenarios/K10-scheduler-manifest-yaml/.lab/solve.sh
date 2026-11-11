nxi "$CP" >/dev/null <<'__X__'
set -eu
f=/etc/kubernetes/manifests/kube-scheduler.yaml
lead=$(grep -m1 -E '^ +- --leader-elect' "$f" | sed -E 's/^( +).*/\1/')
sed "s/^\t- --v=2/${lead}- --v=2/" "$f" > /var/tmp/kube-scheduler.yaml
mv /var/tmp/kube-scheduler.yaml "$f"
__X__
ready() { [ "$(kx -n kube-system get pod "kube-scheduler-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 180 ready || true
