# Someone ran "kubectl delete ns prod"
**INC-2815** · P1 · Reporter: on-call

A cleanup script deleted namespace `prod` ten minutes ago: the `orders` Deployment, its ConfigMap `orders-config`
and Secret `orders-db` are gone, and nothing of it is in Git. The nightly etcd backup ran just before:
`/var/backups/etcd/etcd-nightly.db` on `k8s-cp1`. Bring `prod` back **as it was** (same objects, same UIDs). Work
created in other namespaces since the backup can be lost - it's a small cluster and on-call agreed.

**Test**: namespace `prod` and its Deployment, ConfigMap and Secret are back with their original UIDs and data;
`orders` runs 2 Ready pods; the API answers, all nodes are Ready and etcd runs from restored data; only the 4
control-plane manifests are in `/etc/kubernetes/manifests`.
