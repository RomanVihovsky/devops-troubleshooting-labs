# V05 - a volume the pod's user can't write

**Root cause**: the NFS CSI driver creates each volume as a directory owned by root, mode 755. The pod runs as
uid/gid 1000 with no `fsGroup`, so it can read the volume and not write it. labapp checks `DATA_DIR` at start
and exits. The namespace's `restricted` Pod Security level forbids the usual workaround (an init container
running as root to `chown`).

**Diagnosis**
```
kubectl -n uploads logs deploy/uploads --previous          # DATA_DIR /data is not writable: permission denied
kubectl get csidriver nfs.csi.k8s.io -o jsonpath='{.spec.fsGroupPolicy}'; echo    # File
# a throwaway pod (restricted-compliant) mounting the PVC: ls -ldn /data  -> 0 0 drwxr-xr-x
```

**Fix**: `securityContext.fsGroup: 1000` on the pod (plus `fsGroupChangePolicy: OnRootMismatch` for big
volumes). When the kubelet mounts the volume, it changes group ownership to 1000, adds group write and
setgid, and adds 1000 to the container's supplementary groups.

**Interview notes**
- `fsGroup` works when the volume plugin supports ownership management: CSI drivers declare it with
  `fsGroupPolicy` (`File` = always, `ReadWriteOnceWithFSType` = only RWO with an fsType, `None`). hostPath
  and local-path volumes ignore it (the reason this lab uses NFS here).
- NFS and `root_squash`: with root squashing the kubelet's chown fails. This lab's export uses
  `no_root_squash`. On real filers, fix the export's ownership or use `anonuid`/`anongid`.
- NFS checks groups on the **server**: Ubuntu's nfs-kernel-server runs `rpc.mountd --manage-gids`, which ignores
  the supplementary groups the client sends and looks up the uid's groups in the server's `/etc/group`. `fsGroup`
  is only a supplementary group, so it works here because the pod's `runAsGroup` is the same gid (V07 needs the
  same).
- `OnRootMismatch` skips the recursive chown when the top directory already matches. On millions of files
  that turns a 10-minute pod start into seconds.
- Restricted PSA: runAsNonRoot, no privilege escalation, drop ALL capabilities, seccomp RuntimeDefault.
  `fsGroup` is allowed.
