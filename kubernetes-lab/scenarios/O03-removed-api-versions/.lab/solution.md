# O03 - removed API versions

**Root cause**: `policy/v1beta1` PodDisruptionBudget was removed in 1.25, and the `v1beta1` Ingress in 1.22. The API
server no longer serves those versions, so a manifest that uses them is rejected with *no matches for kind*.
The objects themselves still exist as v1 (stored objects were migrated); only the old manifests broke.

**Diagnosis**
```
kubectl api-resources | grep -iE 'poddisruptionbudgets|ingresses'     # policy/v1, networking.k8s.io/v1
kubectl explain ingress.spec --api-version=networking.k8s.io/v1
```

**Fix**: PDB → `policy/v1` (same fields). Ingress → `networking.k8s.io/v1` with `pathType` and
`backend.service.{name, port.number}`.

**Interview notes**
- Before an upgrade, find removed APIs in **manifests and charts** (pluto, kubent) and in what clients request
  (the `apiserver_requested_deprecated_apis` metric, audit annotations `k8s.io/deprecated`).
- Deprecation policy: beta APIs live at least 9 months / 3 releases after deprecation. GA versions are not
  removed within a major version.
- Helm releases can get stuck when their stored manifest uses a removed API: `helm-mapkubeapis` rewrites the
  release record.
