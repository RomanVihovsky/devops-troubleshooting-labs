# Y03 - the ExternalSecret points at a path that doesn't exist

**Root cause**: the "cleanup" set `secret.externalSecret.remoteKey: shop/app`; OpenBao has the kv-v2 secret
at `secret/shop`. ESO reports `SecretSyncedError` but keeps the existing Secret - until someone deleted it.
New pods then fail with `CreateContainerConfigError: secret "shop-secrets" not found`.

**Diagnosis**
```
kubectl -n shop get externalsecret shop-secrets -o jsonpath='{.status.conditions}'
bao kv list -mount=secret /; bao kv get -mount=secret shop
git -C workspace/gitops log -p -1 -- envs/shop
```

**Fix**: `remoteKey: shop` in Git, push, refresh; ESO recreates the Secret, the pods start.

**Interview notes**
- ESO's default deletion behaviour keeps the last good Secret on provider errors - the outage starts only
  when the Secret disappears (manual delete, new namespace, new cluster). Alert on the ExternalSecret's
  Ready condition.
- "Copy the secret to the new path" would hide a Git bug and leave two copies to rotate.
- kv-v2 paths: `secret/shop` in the CLI = `secret/data/shop` in policies and the API; ESO's `remoteRef.key`
  is the CLI form when the store sets `version: v2`.
