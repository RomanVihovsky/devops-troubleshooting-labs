# T05 · Storage: local-path vs NFS RWX, snapshots, reclaim policy
**Learn** · two StorageClasses, two very different volumes · ~40 min

The cluster has `local-path` (default: a directory on one node) and `nfs` (csi-driver-nfs on k8s-gw, RWX,
snapshots). Work in namespace `t05` with the files in `workspace/T05/`.

1. `kubectl apply -f local.yaml`. Find the PersistentVolume it got: on **which node** does it live
   (`nodeAffinity`)? Note it in `answers.yaml`. What happens to `local-writer` if that node dies?
2. That data matters: make its PV survive the claim - **reclaim policy `Retain`**.
3. `shared.yaml`: finish the TODOs - a `ReadWriteMany` claim `shared` on `nfs`, and the 2 `writers` on
   **two different nodes**. Both append their node name to `/data/log` - check that each one sees the
   other's lines.
4. `restore.yaml`: a **VolumeSnapshot** `shared-snap` of `shared` (class `nfs`), a new claim `restored`
   **from that snapshot**, and the pod `reader` that mounts it.

**Test**: `local-data` is Bound on local-path and its PV is Retain (`answers.yaml` names its node); `shared`
is RWX on nfs, the 2 writers run on 2 nodes and the log has lines from both; `shared-snap` is ready and
`reader` sees the log in the restored volume.
