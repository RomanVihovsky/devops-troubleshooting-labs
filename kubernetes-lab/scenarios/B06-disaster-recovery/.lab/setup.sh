# B06: ledger with data on a Retain volume; etcd backup; prod deleted; the API server cert renewed with a 3-minute life
nx "$CP" 'rm -rf /var/backups/etcd /var/lib/etcd-restored' </dev/null
kx get storageclass nfs -o json | jq '{apiVersion, kind, metadata: {name: "nfs-retain"}, provisioner, parameters,
  reclaimPolicy: "Retain", volumeBindingMode, mountOptions, allowVolumeExpansion} | with_entries(select(.value != null))' | ka -f -
kns prod
ka -f - <<'YML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: ledger-data, namespace: prod}
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: nfs-retain
  resources: {requests: {storage: 1Gi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger, namespace: prod}
spec:
  replicas: 1
  strategy: {type: Recreate}
  selector: {matchLabels: {app: ledger}}
  template:
    metadata: {labels: {app: ledger}}
    spec:
      securityContext: {runAsUser: 10001, runAsGroup: 10001, fsGroup: 10001}
      containers:
        - name: ledger
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: ledger}, {name: DATA_DIR, value: /data}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
          volumeMounts: [{name: data, mountPath: /data}]
      volumes: [{name: data, persistentVolumeClaim: {claimName: ledger-data}}]
YML
wait_rollout prod deploy/ledger 180
bal="balance-$(openssl rand -hex 8)"; remember b06_balance "$bal"
kx -n prod exec deploy/ledger -- labapp get -X PUT -d "$bal" http://localhost:8080/kv/balance >/dev/null
remember b06_ns "$(kx get ns prod -o jsonpath='{.metadata.uid}')"
remember b06_deploy "$(kx -n prod get deploy ledger -o jsonpath='{.metadata.uid}')"
remember b06_pvc "$(kx -n prod get pvc ledger-data -o jsonpath='{.metadata.uid}')"
remember b06_inode "$(nx "$CP" 'stat -c %i /var/lib/etcd/member' </dev/null)"
nx "$CP" "mkdir -p /var/backups/etcd && etcdctl $ETCD_FLAGS snapshot save /var/backups/etcd/nightly.db >/dev/null 2>&1" </dev/null
# the "certificate test": only the API server cert, 3 minutes
nxi "$CP" >/dev/null <<'__X__'
set -eu
python3 - <<'PY'
import yaml
docs = [d for d in yaml.safe_load_all(open("/etc/kubernetes/kubeadm/init.yaml")) if d]
for d in docs:
    if d["kind"] == "ClusterConfiguration":
        d["certificateValidityPeriod"] = "3m0s"
yaml.safe_dump_all(docs, open("/var/tmp/b06.yaml", "w"), sort_keys=False)
PY
kubeadm certs renew apiserver --config /var/tmp/b06.yaml >/dev/null 2>&1
rm -f /var/tmp/b06.yaml
python3 - <<'PY'
import time, yaml
f = "/etc/kubernetes/manifests/kube-apiserver.yaml"; d = yaml.safe_load(open(f))
d["metadata"].setdefault("annotations", {})["lab.k8slab/cert-test"] = time.strftime("%Y-%m-%dT%H:%M:%S")
yaml.safe_dump(d, open("/var/tmp/kube-apiserver.yaml", "w"), sort_keys=False)
PY
mv /var/tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
__X__
sleep 20
retry 180 kx get --raw /readyz || die "API not back after the cert test"
kx delete namespace prod --wait=true --timeout=180s >/dev/null
expired() { local o; o=$(KX_TIMEOUT=5s kx get --raw /readyz 2>&1) && return 1; grep -qiE 'expired|x509' <<<"$o"; }
retry 300 expired || die "the API server cert did not expire"
