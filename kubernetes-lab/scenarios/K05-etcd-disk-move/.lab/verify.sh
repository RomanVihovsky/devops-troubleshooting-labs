api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
moved() {
  nx "$CP" "python3 -c 'import yaml; d = yaml.safe_load(open(\"/etc/kubernetes/manifests/etcd.yaml\")); c = d[\"spec\"][\"containers\"][0]
v = [x[\"hostPath\"] for x in d[\"spec\"][\"volumes\"] if x[\"name\"] == \"etcd-data\"][0]
m = [x[\"mountPath\"] for x in c[\"volumeMounts\"] if x[\"name\"] == \"etcd-data\"][0]
dd = [a.split(\"=\", 1)[1] for a in c[\"command\"] if a.startswith(\"--data-dir=\")][0]
import sys; sys.exit(0 if v == {\"path\": \"/var/lib/etcd-disk\", \"type\": \"Directory\"} and m == dd else 1)'" </dev/null
}
in_use() { nx "$CP" 'pgrep -a -x etcd' </dev/null 2>/dev/null | grep -q -- '--data-dir=/var/lib/etcd-disk'; }
marker() { [ "$(kx -n default get configmap migration-marker -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall k05_uid)" ]; }
check_eventually 240 "the API answers" api_ok
check "etcd-data is /var/lib/etcd-disk with type Directory, --data-dir matches" moved
check "the running etcd uses /var/lib/etcd-disk" in_use
check "ConfigMap migration-marker still exists (no data lost)" marker
check_eventually 180 "all nodes Ready" nodes_ready
verdict
