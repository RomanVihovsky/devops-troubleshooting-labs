kx apply -f local.yaml >/dev/null
kx -n t05 wait --for=jsonpath='{.status.phase}'=Bound pvc/local-data --timeout=120s >/dev/null
pv=$(kx -n t05 get pvc local-data -o jsonpath='{.spec.volumeName}')
kx patch pv "$pv" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' >/dev/null
printf 'local_pv_node: %s\n' "$(kx get pv "$pv" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')" > answers.yaml
python3 - <<'PY'
import yaml
docs = list(yaml.safe_load_all(open("shared.yaml")))
docs[0]["spec"].update(accessModes=["ReadWriteMany"], storageClassName="nfs")
docs[1]["spec"]["template"]["spec"]["topologySpreadConstraints"] = [{"maxSkew": 1, "topologyKey": "kubernetes.io/hostname",
    "whenUnsatisfiable": "DoNotSchedule", "labelSelector": {"matchLabels": {"app": "writers"}}}]
yaml.safe_dump_all(docs, open("shared.yaml", "w"), sort_keys=False)
PY
kx apply -f shared.yaml >/dev/null
wait_rollout t05 deploy/writers
sleep 12   # both writers append at least twice before the snapshot
cat > restore.yaml <<'YML'
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata: {name: shared-snap, namespace: t05}
spec: {volumeSnapshotClassName: nfs, source: {persistentVolumeClaimName: shared}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: restored, namespace: t05}
spec:
  accessModes: [ReadWriteMany]
  storageClassName: nfs
  resources: {requests: {storage: 64Mi}}
  dataSource: {apiGroup: snapshot.storage.k8s.io, kind: VolumeSnapshot, name: shared-snap}
---
apiVersion: v1
kind: Pod
metadata: {name: reader, namespace: t05}
spec:
  containers:
    - name: r
      image: docker.io/library/busybox:1.37
      command: [sh, -c, 'sleep 86400']
      volumeMounts: [{name: data, mountPath: /data}]
  volumes:
    - {name: data, persistentVolumeClaim: {claimName: restored}}
YML
kx apply -f restore.yaml >/dev/null
kx -n t05 wait --for=condition=Ready pod/reader --timeout=180s >/dev/null
