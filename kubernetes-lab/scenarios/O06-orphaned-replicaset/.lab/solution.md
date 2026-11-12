# O06 - orphans

**Root cause**: `kubectl delete deployment oldapp --cascade=orphan` removes the Deployment and **orphans** its
dependents: the garbage collector strips the ownerReference from the ReplicaSet instead of deleting it. A
ReplicaSet is itself a controller, so it kept its 3 pods running.

**Diagnosis**
```
kubectl -n retired get rs,pods -l app=oldapp
kubectl -n retired get rs -l app=oldapp -o jsonpath='{.items[*].metadata.ownerReferences}'; echo   # empty
```

**Fix**: delete the ReplicaSet (default cascade: background), and its pods go with it.

**Interview notes**
- Cascades: `background` (default: delete the owner, the GC deletes the dependents), `foreground` (dependents
  first; the owner shows `foregroundDeletion`), `orphan` (keep the dependents).
- Orphaning is useful when you want to **replace** a controller without touching its pods: re-create a
  Deployment with the same selector and it adopts the ReplicaSet. StatefulSet volumeClaimTemplate changes
  are done this way (V06).
- ownerReferences drive garbage collection for everything: Jobs/pods, Services/EndpointSlices, CRs and their
  children.
