# C06 - immutable config is changed by replacing it

**Root cause**: `immutable: true` makes a ConfigMap's `data`/`binaryData` read-only for its whole life. That's
the point (the kubelet stops watching it), and also the reason the apply was rejected.

**Diagnosis**
```
kubectl -n pricing get cm pricing-config -o jsonpath='{.immutable}'; echo
kubectl apply -f workspace/C06/pricing.yaml      # ... field is immutable when `immutable` is set
```

**Fix**: a new immutable ConfigMap (`pricing-config-v2` with USD), the Deployment pointed at it → a rolling update.
Keep v1 for a quick rollback, delete it later.

**Interview notes**
- Immutable ConfigMaps/Secrets: protection against accidental updates that would hit running pods, and much
  less load on the API server (no watches). They can only be deleted and re-created.
- Name-hashing does this for you: Kustomize `configMapGenerator` (name + content hash) or Helm with a
  checksum in the name. Every change is a new object and a rollout, and rollback restores the old reference.
- Deleting and re-creating it under the same name is not a fix: running pods keep their old env, and pods
  that start meanwhile fail with "not found".
