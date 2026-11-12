# O02 - an orphaned finalizer

**Root cause**: `orders-db` carries the finalizer `example.com/drop-database`. On delete, the API server only sets
`deletionTimestamp` and waits for the finalizer list to become empty. Normally the operator drops the database
and removes its finalizer. The operator is gone, so the object waits forever, and `kubectl delete` waits with
it.

**Diagnosis**
```
kubectl -n dbs get database orders-db -o jsonpath='{.metadata.deletionTimestamp} {.metadata.finalizers}'; echo
kubectl get pods -A | grep -i operator        # nothing handles example.com
```

**Fix**: since the external work is done (the DBA dropped the database), remove the finalizer from **that**
object only.

**Interview notes**
- Finalizers guard external state (cloud disks, DNS records, databases). Removing one by hand skips that
  cleanup. Confirm the external resource is gone first, or you leak (and pay for) it.
- `kubectl delete --wait=false` returns at once. The object still waits.
- Built-in finalizers to recognise: `kubernetes.io/pvc-protection` (V08), `kubernetes.io/pv-protection`,
  `foregroundDeletion`, `orphan`.
