# K11 - etcd ran out of quota

**Root cause**: etcd's backend quota (`--quota-backend-bytes`) was set to barely above the database size. The import
job's ~1 MB ConfigMaps filled it; etcd raised the **NOSPACE** alarm and now only serves reads and deletes. Every
write in the cluster fails - including the kubelets' lease renewals, so nodes go NotReady.

**Diagnosis** (on `k8s-cp1`, `E="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt
--cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"`):
```
etcdctl $E endpoint status -w table      # DB SIZE vs the quota in etcd.yaml
etcdctl $E alarm list                    # memberID:... alarm:NOSPACE
kubectl get configmaps -A --sort-by=.metadata.creationTimestamp | tail
```

**Fix** - in this order:
1. raise the quota (drop the flag: 2 GiB default; max recommended 8 GiB) - etcd restarts;
2. delete the junk (`kubectl -n import delete configmap --all` - deletes are allowed under NOSPACE);
3. `etcdctl compact <current revision>` - drops old revisions;
4. `etcdctl defrag` - gives the freed pages back (blocks the member while it runs);
5. `etcdctl alarm disarm` - etcd accepts writes again.

**Interview notes**
- `etcdctl endpoint health` says *unhealthy* as long as any alarm is active; `endpoint status` still answers.
- The API server compacts automatically every 5 min (`--etcd-compaction-interval`); defrag is always manual
  (or a CronJob / operator).
- Watch `etcd_mvcc_db_total_size_in_bytes` vs `etcd_server_quota_backend_bytes`; alert at 80 %.
- Large objects (ConfigMaps/Secrets up to 1 MiB, CRDs with big status) and event floods are the usual causes.
