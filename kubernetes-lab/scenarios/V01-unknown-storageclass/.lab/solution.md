# V01 - a StorageClass that doesn't exist

**Root cause**: `storageClassName: fast-ssd` - no such class here; no provisioner acts, the PVC stays
Pending ("storageclass.storage.k8s.io fast-ssd not found"), the pod waits for it.

**Fix**: an existing class (or none = default); PVC classes are immutable → recreate the PVC.

**Interview notes**
- Portable manifests: leave `storageClassName` out (default class) or template it per environment.
- PVC Pending reasons: unknown class, no default class (V02), WaitForFirstConsumer (normal until a pod is
  scheduled), provisioner down, quota.
