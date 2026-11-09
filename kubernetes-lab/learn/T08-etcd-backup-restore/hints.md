## Hint 1
```
export ETCDCTL_API=3
etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /var/backups/etcd-t08.db
etcdutl snapshot status /var/backups/etcd-t08.db -w table
```

## Hint 2
```
etcdutl snapshot restore /var/backups/etcd-t08.db --data-dir /var/lib/etcd-t08 \
  --name k8s-cp1 --initial-cluster k8s-cp1=https://192.168.56.21:2380 \
  --initial-advertise-peer-urls https://192.168.56.21:2380
```
The values are in `/etc/kubernetes/manifests/etcd.yaml` (`--name`, `--initial-cluster`,
`--initial-advertise-peer-urls`).

## Hint 3
In `etcd.yaml` change only the **hostPath** of the `etcd-data` volume to `/var/lib/etcd-t08` (the container
still sees `/var/lib/etcd`). Don't keep a backup copy of the manifest in that directory - kubelet runs every
file there. The kubelet restarts etcd within ~20 s; then restart the API server (e.g. `crictl stop
$(crictl ps --name kube-apiserver -q)`) and watch `kubectl get --raw /readyz`.
