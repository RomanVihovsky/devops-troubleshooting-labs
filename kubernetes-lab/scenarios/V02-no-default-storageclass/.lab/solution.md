# V02 - no default StorageClass

**Root cause**: the `is-default-class` annotation was removed from local-path; PVCs without a class have no
class to provision from ("no persistent volumes available for this claim and no storage class is set").

**Fix**: mark one class as default; the pending PVC gets it assigned (retroactive default, GA 1.28).

**Interview notes**
- Exactly one default: with two defaults, the newest wins (since 1.26) - surprising, avoid it.
- `storageClassName: ""` (empty string) means "no class, bind to a pre-created PV only" - not "default".
