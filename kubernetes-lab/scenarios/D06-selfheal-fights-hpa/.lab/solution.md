# D06 - self-heal vs the HPA: one owner per field

**Root cause**: the chart renders `spec.replicas: 2`, and an HPA added with `kubectl` sets 3. The live object
differs from Git, so Argo CD marks demo OutOfSync, and self-heal syncs `replicas: 2` back. The HPA scales to 3
again, and so on. Two controllers own one field.

**Diagnosis**
```
argocd app diff demo                    # - replicas: 2 / + replicas: 3
argocd app history demo                 # an auto-sync every minute or so
kubectl -n demo get hpa demo            # MINPODS 3
kubectl -n demo get events --sort-by=.lastTimestamp | grep -i scaled
```

**Fix** (choose one; both are in Git):
1. The HPA belongs in Git, and the chart stops rendering replicas: in `envs/demo/values.yaml`
   `autoscaling: {enabled: true, minReplicas: 3, maxReplicas: 6}`. The chart renders the HPA and omits
   `replicas`. The hand-made HPA of the same name is adopted.
2. Keep the replicas in the chart, but tell Argo CD to ignore them. In `apps/demo.yaml`:
   ```yaml
   spec:
     ignoreDifferences:
       - {group: apps, kind: Deployment, jsonPointers: [/spec/replicas]}
     syncPolicy:
       syncOptions: [CreateNamespace=true, RespectIgnoreDifferences=true]
   ```
   Without `RespectIgnoreDifferences`, every sync (a new commit) still applies `replicas: 2` for a moment.

**Interview notes**
- Rule: a field has one owner. HPA ↔ `replicas`, VPA ↔ resources, cert-manager ↔ certificate Secrets,
  mutating webhooks ↔ injected fields. GitOps must not render what another controller manages.
- `ignoreDifferences` only changes the *diff*; without `RespectIgnoreDifferences` the sync still writes the
  ignored field.
- Server-side apply (`ServerSideApply=true`) makes ownership explicit with managedFields, but the field still
  must not be in the manifest.
- The same fight appears with `kubectl scale` during an incident: with self-heal on, the next reconcile
  undoes it. Scale through Git, or switch self-heal off on purpose.
