# W09 - a paused Deployment

**Root cause**: someone ran `kubectl rollout pause` (and forgot it). A paused Deployment accepts spec changes
but does not reconcile the template: no new ReplicaSet, no rollout, no error. `spec.paused: true` and the
`Progressing` condition's reason `DeploymentPaused` are the only signs.

**Diagnosis**
```
kubectl -n blog get deploy blog -o jsonpath='{.spec.paused} {.spec.template.spec.containers[0].image}'; echo
kubectl -n blog get rs -o wide                     # only the 1.3 ReplicaSet
kubectl -n blog rollout status deploy/blog         # Waiting for ... paused
```

**Fix**: `kubectl -n blog rollout resume deploy/blog`.

**Interview notes**
- Pause/resume batches several edits (image + env + resources) into one rollout instead of three.
- Scaling still works while paused (it's not a template change); rollbacks (`undo`) don't.
- With GitOps the "pause" is usually `syncPolicy.automated` turned off. Check that too when "nothing
  happens".
