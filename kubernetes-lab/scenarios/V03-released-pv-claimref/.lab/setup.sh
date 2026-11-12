# V03: a static NFS PV (Retain) that was bound to a claim which is gone now -> Released with a stale claimRef
nx k8s-gw 'mkdir -p /srv/nfs/lab-v03-archive && echo "orders 2016-2026" > /srv/nfs/lab-v03-archive/index.txt' </dev/null
kns archive
ka -f - <<'YML'
apiVersion: v1
kind: PersistentVolume
metadata: {name: orders-archive}
spec:
  capacity: {storage: 1Gi}
  accessModes: [ReadWriteMany]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  mountOptions: [nfsvers=4.1]
  nfs: {server: 192.168.56.20, path: /srv/nfs/lab-v03-archive}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: archive-old, namespace: archive}
spec:
  accessModes: [ReadWriteMany]
  storageClassName: ""
  volumeName: orders-archive
  resources: {requests: {storage: 1Gi}}
YML
bound() { [ "$(kx get pv orders-archive -o jsonpath='{.status.phase}')" = Bound ]; }
retry 60 bound || die "PV never bound"
remember v03_pv "$(kx get pv orders-archive -o jsonpath='{.metadata.uid}')"
kx -n archive delete pvc archive-old >/dev/null
released() { [ "$(kx get pv orders-archive -o jsonpath='{.status.phase}')" = Released ]; }
retry 60 released || die "PV not Released"
ka -f archive.yaml
