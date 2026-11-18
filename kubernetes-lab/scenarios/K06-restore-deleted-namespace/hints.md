## Hint 1
`./lab node cp1`; `etcdutl snapshot status /var/backups/etcd/etcd-nightly.db -w table`. A restore never writes into
the running data dir: it creates a **new** one. Look at `/etc/kubernetes/manifests/etcd.yaml` - which flags and which
hostPath decide where etcd's data lives?

## Hint 2
`etcdutl snapshot restore <db> --data-dir /var/lib/etcd-restored --name k8s-cp1 --initial-cluster
k8s-cp1=https://<cp1 ip>:2380 --initial-advertise-peer-urls https://<cp1 ip>:2380` (name and URLs from the
manifest), then point the `etcd-data` hostPath at the new dir. Don't leave copies of manifests in that directory.

## Hint 3
The kubelet restarts etcd when the manifest changes; the API server keeps a watch cache of the old data - restart it
too (`crictl stop` its container, or touch its manifest). Then `kubectl get ns prod` - and look closely at the restored
pods: `kubectl -n prod exec deploy/orders -- labapp get localhost:8080/ready`.
