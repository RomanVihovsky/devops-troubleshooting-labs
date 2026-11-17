# B04 - a StatefulSet migration with three layers of faults

1. **Storage**: `storageClassName: fast-ssd` (copied from prod, where it maps to gp3) doesn't exist here -> PVC Pending
   -> pod Pending. `volumeClaimTemplates` are immutable (V06): delete the StatefulSet **and** the Pending PVC, then
   apply with an existing class (or none = the default, `local-path`).
2. **Secret key**: `secretKeyRef.key: password`, but the DBA's Secret has `postgres-password` ->
   *CreateContainerConfigError: couldn't find key password*. Point at the right key (don't rename the DBA's Secret
   under the app - orders mounts it too).
3. **Headless Service**: `postgres-0.postgres.<ns>.svc` records exist only for a Service with `clusterIP: None` that
   matches the StatefulSet's `serviceName`. A ClusterIP can't be changed to None - delete and re-create.

Then orders connects to the primary by name, `AUTO_MIGRATE` creates and seeds the schema, and the data survives a
restart of `postgres-0` because it lives on `data-postgres-0`.

**Interview notes**
- StatefulSet guarantees: stable names, stable per-pod DNS (via the headless Service), stable volumes per ordinal,
  ordered start/stop.
- `PGDATA` in a subdirectory of the mount avoids "directory not empty" (lost+found on block volumes).
- Hand-written manifests from Helm output carry environment-specific values (classes, hostnames) - template them.
