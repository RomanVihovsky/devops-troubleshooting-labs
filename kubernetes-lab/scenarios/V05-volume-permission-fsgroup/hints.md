## Hint 1
`kubectl -n uploads logs deploy/uploads --previous`, then look at the volume from a pod that starts:
`kubectl -n uploads debug ...` or a throwaway pod mounting the same PVC: `ls -ldn /data`. Who owns it?

## Hint 2
The NFS provisioner creates each volume's directory as root, mode 755. User 1000 can read, not write. Kubernetes
can hand the volume to the pod's group: `securityContext.fsGroup`. This CSI driver supports it
(`kubectl get csidriver nfs.csi.k8s.io -o jsonpath='{.spec.fsGroupPolicy}'`).

## Hint 3
Pod-level `securityContext.fsGroup: 1000` (optionally `fsGroupChangePolicy: OnRootMismatch`) in
`uploads.yaml`, apply. The kubelet chowns/chmods the volume to group 1000 (setgid) when it mounts it.
