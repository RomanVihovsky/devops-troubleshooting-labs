# R08: w3's kubelet keeps nodefs.available above what is free (free% + 5) - permanent DiskPressure
kns ingest
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: ingest, namespace: ingest}
spec:
  replicas: 2
  selector: {matchLabels: {app: ingest}}
  template:
    metadata: {labels: {app: ingest}}
    spec:
      nodeSelector: {kubernetes.io/hostname: k8s-w3}
      containers:
        - name: ingest
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: DISK_CACHE_MB, value: "16"}, {name: CACHE_DIR, value: /scratch}]
          volumeMounts: [{name: scratch, mountPath: /scratch}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 5}
      volumes: [{name: scratch, emptyDir: {}}]
YML
wait_rollout ingest deploy/ingest
free=$(kx get --raw /api/v1/nodes/k8s-w3/proxy/stats/summary | jq '.node.fs.availableBytes * 100 / .node.fs.capacityBytes | floor')
thr="$(( free + 5 ))%"
remember r08_threshold "$thr"
nxi k8s-w3 >/dev/null <<__X__
set -eu
python3 - <<'PY'
import yaml
f = "/var/lib/kubelet/config.yaml"; d = yaml.safe_load(open(f))
d["evictionHard"] = {"nodefs.available": "$thr", "memory.available": "100Mi"}
yaml.safe_dump(d, open(f, "w"), sort_keys=False)
PY
systemctl restart kubelet
__X__
pressure() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}')" = True ]; }
retry 180 pressure || die "no DiskPressure on k8s-w3"
pending() { kx -n ingest get pods -l app=ingest --field-selector=status.phase=Pending --no-headers 2>/dev/null | grep -q .; }
retry 180 pending || die "ingest was not evicted"
