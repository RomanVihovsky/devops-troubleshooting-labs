# V03 - a Released PV keeps its old claimRef

**Root cause**: with `Retain`, deleting the claim leaves the PV `Released`, still pointing at the old
claim (`spec.claimRef` with its uid). The binder won't give it to anyone else - by design, so a new tenant
can't read the previous one's data by accident.

**Fix**: after checking the data is meant to be reused, remove `spec.claimRef`; the PV becomes Available and
the claim that names it (`volumeName`) binds.

**Interview notes**
- Reclaim policies: Delete (default for dynamic PVs), Retain (manual cleanup/reuse), Recycle (deprecated).
- Pre-binding: the claim's `volumeName` + optionally the PV's `claimRef` (namespace/name, no uid) reserves a
  PV for one claim.
- Changing a dynamic PV to Retain before deleting the claim is the "don't lose this" move (T05).
