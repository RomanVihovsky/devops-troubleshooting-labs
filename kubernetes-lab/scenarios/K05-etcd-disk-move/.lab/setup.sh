# K05: etcd data copied to /var/lib/etcd-disk; manifest: --data-dir + mountPath right, hostPath typo + type Directory
kx -n default create configmap migration-marker --from-literal=moved="$(date -u +%FT%TZ)" --dry-run=client -o yaml | ka -f -
remember k05_uid "$(kx -n default get configmap migration-marker -o jsonpath='{.metadata.uid}')"
nxi "$CP" >/dev/null <<'__X__'
set -eu
rm -rf /var/lib/etcd-disk
mv /etc/kubernetes/manifests/etcd.yaml /var/tmp/etcd.yaml
for _ in $(seq 60); do crictl ps --name '^etcd$' -q | grep -q . || break; sleep 2; done
cp -a /var/lib/etcd /var/lib/etcd-disk
python3 - <<'PY'
import yaml
f = "/var/tmp/etcd.yaml"; d = yaml.safe_load(open(f)); c = d["spec"]["containers"][0]
c["command"] = [a if not a.startswith("--data-dir=") else "--data-dir=/var/lib/etcd-disk" for a in c["command"]]
for m in c["volumeMounts"]:
    if m["name"] == "etcd-data":
        m["mountPath"] = "/var/lib/etcd-disk"
for v in d["spec"]["volumes"]:
    if v["name"] == "etcd-data":
        v["hostPath"] = {"path": "/var/lib/etcd-disks", "type": "Directory"}   # CHG-1207 (typo)
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
mv /var/tmp/etcd.yaml /etc/kubernetes/manifests/etcd.yaml
__X__
api_down() { ! KX_TIMEOUT=5s kx get --raw /readyz >/dev/null 2>&1; }
retry 180 api_down || die "the API server did not go down"
