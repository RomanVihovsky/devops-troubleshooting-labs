# K11: --quota-backend-bytes = the current DB size + 10 MiB, then ~1 MB ConfigMaps until NOSPACE
db=$(nx "$CP" "etcdctl $ETCD_FLAGS endpoint status -w json" </dev/null | jq '.[0].Status.dbSize')
[ -n "$db" ] && [ "$db" -gt 0 ] || die "no etcd db size"
q=$(( db + 10 * 1048576 ))
nxi "$CP" >/dev/null <<__X__
set -eu
python3 - <<'PY'
import yaml
f = "/etc/kubernetes/manifests/etcd.yaml"; d = yaml.safe_load(open(f)); c = d["spec"]["containers"][0]
c["command"] = [a for a in c["command"] if not a.startswith("--quota-backend-bytes")] + ["--quota-backend-bytes=$q"]
yaml.safe_dump(d, open("/var/tmp/etcd.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/etcd.yaml /etc/kubernetes/manifests/etcd.yaml
__X__
sleep 15
retry 240 kx get --raw /readyz || die "API not back after the quota change"
kns import
blob=$(mktemp); head -c 700000 /dev/urandom | base64 -w0 > "$blob"
full=""
for i in $(seq 1 60); do
  o=$(kx -n import create configmap "batch-$i-cache" --from-file=data="$blob" 2>&1) && continue
  if grep -q 'database space exceeded' <<<"$o"; then full=1; break; fi
done
rm -f "$blob"
[ -n "$full" ] || die "etcd never filled up"
alarm() { local o; o=$(nx "$CP" "etcdctl $ETCD_FLAGS alarm list" </dev/null 2>/dev/null) || true; grep -q NOSPACE <<<"$o"; }
retry 30 alarm || die "no NOSPACE alarm"
