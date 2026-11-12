# O01 - a namespace waiting for finalizers that nobody will run

**Root cause**: deleting a namespace deletes everything in it, and each object honours its own finalizers. The
`Backup` objects carry `example.com/backup-cleanup`, which only the (uninstalled) backup operator would remove
after cleaning up its external backups. So the objects never went, and the namespace's own `kubernetes`
finalizer waited for them: `NamespaceFinalizersRemaining`.

**Diagnosis**
```
kubectl get ns old-team -o jsonpath='{.status.conditions}' | jq      # SomeFinalizersRemain: example.com/backup-cleanup in 2 resource instances
kubectl api-resources --verbs=list --namespaced -o name | xargs -n1 kubectl -n old-team get --ignore-not-found --show-kind
kubectl -n old-team get backups -o jsonpath='{range .items[*]}{.metadata.name} {.metadata.finalizers}{"\n"}{end}'
```

**Fix**: decide that the external cleanup is not needed (or do it by hand), then remove the finalizers from those
objects. The namespace controller finishes.

**Interview notes**
- Don't force-finalize the namespace (`PUT /api/v1/namespaces/x/finalize` with empty finalizers, a widely
  copied "fix"). It removes the namespace while its objects stay in etcd as orphans, which reappear if the
  namespace is ever re-created.
- Uninstall operators in order: delete their CRs **while the operator runs**, then the operator, then the
  CRDs.
- `NamespaceContentRemaining` vs `NamespaceFinalizersRemaining` vs `NamespaceDeletionDiscoveryFailure` (an
  unavailable APIService, often metrics or a webhook) are three different problems.
