# V08 - pvc-protection: the claim is still in use

**Root cause**: the live Deployment still mounts `forms-data`; only the file in Git/workspace was updated.
Deleting a claim in use sets deletionTimestamp, but the `kubernetes.io/pvc-protection` finalizer keeps it
until no pod uses it - Terminating "forever".

**Fix**: roll the Deployment onto `forms-data-v2` (apply the file); the old pod goes, the finalizer is
removed, the claim (and its PV, policy Delete) disappear.

**Interview notes**
- Finalizers are "don't delete yet" markers owned by a controller. Removing them by hand (patch
  finalizers: null) skips the cleanup they guard - for PVCs: data corruption risk while mounted.
- `kubectl describe pvc` shows "Used By"; same pattern for PVs (pv-protection) and namespaces stuck
  Terminating (resources left inside, often with their own finalizers).
