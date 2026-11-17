# O11 - unserving a CRD version, and storage migration

**Root cause**: the upgrade set v1 to `served: false`. The REST endpoint `/apis/example.lab/v1/...` disappeared at
once, so every v1 client gets 404. The objects themselves were written while v1 was the storage version and are
**still stored as v1** in etcd: the API server converts on read (here: conversion `None`, same schema) but never
rewrites them on its own - `status.storedVersions` says `[v1, v2]`.

**Diagnosis**
```
kubectl get crd widgets.example.lab -o jsonpath='{range .spec.versions[*]}{.name} served={.served} storage={.storage}{"\n"}{end}'
kubectl get crd widgets.example.lab -o jsonpath='{.status.storedVersions}'
kubectl -n factory logs deploy/widget-reporter
# on cp1: etcdctl get /registry/example.lab/widgets/factory/gear --print-value-only   -> "apiVersion":"example.lab/v1"
```

**Fix**:
1. serve v1 again (`served: true`, v2 stays `storage: true`) - clients work immediately;
2. migrate storage: rewrite every object so it's persisted as v2 -
   `kubectl -n factory get widgets.v2.example.lab -o json | kubectl replace -f -`
   (in real clusters: the StorageVersionMigrator / `kube-storage-version-migrator`);
3. only then remove v1 from `status.storedVersions` (status subresource patch). Next quarter v1 can be deleted from
   the CRD safely.

**Interview notes**
- Removing a version that's still in `storedVersions` is rejected; deleting it while objects are stored in it
  makes them unreadable.
- Different schemas between versions need a **conversion webhook** (`conversion.strategy: Webhook`).
- Built-in APIs go through the same dance (O03: removed API versions); `kubectl convert` / `pluto` find old
  manifests.
