## Hint 1
`kubectl -n t05 get pvc local-data -o jsonpath='{.spec.volumeName}'`, then `kubectl get pv <pv> -o yaml`:
`spec.nodeAffinity` pins it to one node; the pod can never run elsewhere. `kubectl patch pv <pv> -p
'{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'` - the policy lives on the PV, the StorageClass only
sets the default for new ones.

## Hint 2
RWX: `accessModes: [ReadWriteMany]`, `storageClassName: nfs`. Two nodes: `topologySpreadConstraints`
(`topologyKey: kubernetes.io/hostname`, `maxSkew: 1`, `whenUnsatisfiable: DoNotSchedule`) or a required
`podAntiAffinity` on `app: writers`.

## Hint 3
```yaml
kind: VolumeSnapshot        # apiVersion: snapshot.storage.k8s.io/v1
spec: {volumeSnapshotClassName: nfs, source: {persistentVolumeClaimName: shared}}
---
kind: PersistentVolumeClaim
spec:
  storageClassName: nfs
  dataSource: {apiGroup: snapshot.storage.k8s.io, kind: VolumeSnapshot, name: shared-snap}
```
