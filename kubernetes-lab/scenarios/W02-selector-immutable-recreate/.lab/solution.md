# W02 - changing a Deployment's selector

**Root cause**: in `apps/v1` a Deployment's `spec.selector` is immutable. The selector is how the Deployment
finds its ReplicaSets and pods; changing it would orphan them. v2 changed it (`tier: web`), so the update was
rejected.

**Diagnosis**
```
kubectl apply -f workspace/W02/search-v2.yaml        # spec.selector: Invalid value ... field is immutable
kubectl -n search get deploy search -o jsonpath='{.spec.selector}'; echo
```

**Fix** (an interruption is accepted): delete the Deployment, apply v2. Zero-downtime way: deploy `search-v2`
(new name) beside it, wait for Ready, point the Service at the new labels, delete the old Deployment.

**Interview notes**
- Immutable fields to know: Deployment/ReplicaSet/DaemonSet `spec.selector`, StatefulSet everything except
  replicas/template/updateStrategy/... (`volumeClaimTemplates`, `serviceName`, `podManagementPolicy`), Job
  template, Service `clusterIP`, PVC most of `spec`.
- `kubectl replace --force` = delete + create in one command (same interruption).
- Helm/Argo CD: this is D07. Keep selectors stable, add new labels to the pod template only.
