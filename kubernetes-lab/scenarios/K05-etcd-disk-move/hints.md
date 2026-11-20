## Hint 1
No API, so look on the node: `./lab node cp1`, `crictl ps -a | grep -E 'etcd|apiserver'`, and the kubelet's view:
`journalctl -u kubelet --since -10min | grep -i etcd | tail`.

## Hint 2
The etcd pod never gets a container: the kubelet can't set up one of its volumes. Compare the `etcd-data` hostPath
in `/etc/kubernetes/manifests/etcd.yaml` with the directory that really exists (`ls -d /var/lib/etcd*`).

## Hint 3
Fix the path to `/var/lib/etcd-disk` (keep `type: Directory`), save the manifest (outside the manifests dir first,
then move it in), and wait for etcd and the API server.
