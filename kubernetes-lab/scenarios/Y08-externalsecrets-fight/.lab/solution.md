# Y08 - two ExternalSecrets merging into one Secret

**Root cause**: both `api-key-legacy` (legacy path, every 20 s) and `api-key` (new path, every 30 s) write key
`apikey` of the same Secret with `creationPolicy: Merge`. Merge means "patch my keys into an existing Secret, don't
own it" - nothing stops a second writer, so the Secret holds whichever refreshed last. Both ExternalSecrets come
from Git with self-heal on, so deleting one in the cluster is undone within seconds.

**Diagnosis**
```
kubectl -n partners get externalsecrets -o custom-columns=NAME:.metadata.name,TARGET:.spec.target.name,POLICY:.spec.target.creationPolicy,REFRESH:.spec.refreshInterval
watch -n2 "kubectl -n partners get secret api-key -o jsonpath='{.data.apikey}' | base64 -d"
kubectl -n partners get secret api-key -o yaml        # no ownerReferences: hand-made, merged into
argocd app get partners                               # both ExternalSecrets come from Git
```

**Fix** (in Git): delete `api-key-legacy.yaml`, set `creationPolicy: Owner` on `api-key`, push and sync. With
Owner, ESO creates the Secret with an ownerReference, and a second ExternalSecret targeting it fails loudly instead of
fighting. If the hand-made Secret blocks the takeover, delete it once - ESO re-creates it.

**Interview notes**
- creationPolicy: `Owner` (create + own + delete with the ES), `Orphan` (create, keep on delete), `Merge` (patch
  an existing Secret - for adding keys to Secrets owned by something else), `None` (don't write).
- `deletionPolicy` decides what happens to the Secret when the provider value disappears.
- Migrations between secret paths: switch the single writer's `remoteRef`, don't add a second writer.
