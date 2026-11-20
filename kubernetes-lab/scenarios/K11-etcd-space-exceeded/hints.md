## Hint 1
`./lab node cp1`, then `etcdctl ... endpoint status -w table` and `etcdctl ... alarm list` (the flags are in
`/etc/kubernetes/manifests/etcd.yaml` / `kube-apiserver.yaml`: endpoints and the etcd client certs). Compare DB SIZE
with the `--quota-backend-bytes` flag.

## Hint 2
When the backend reaches its quota etcd raises **NOSPACE** and accepts only reads and deletes. Deleting objects alone
doesn't shrink the file: old revisions stay until a **compaction**, and freed pages are returned only by a
**defrag**. The alarm stays until you disarm it.

## Hint 3
Raise the quota (remove the flag = 2 GiB default) and let etcd restart; `kubectl -n import delete configmap --all`;
`etcdctl compact $(etcdctl endpoint status -w json | jq '.[0].Status.header.revision')`; `etcdctl defrag`;
`etcdctl alarm disarm`.
