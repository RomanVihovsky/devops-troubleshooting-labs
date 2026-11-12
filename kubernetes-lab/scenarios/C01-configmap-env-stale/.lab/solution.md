# C01 - environment variables are read at start

**Root cause**: `promo` gets its settings with `envFrom: configMapRef`. The kubelet resolves those values once,
when it creates the container. Updating the ConfigMap changes the object in the API, not the environment of
running processes.

**Diagnosis**
```
kubectl -n promo get cm promo-config -o jsonpath='{.data.GREETING}'; echo     # Bonjour
kubectl -n promo exec deploy/promo -- printenv GREETING                         # Hello
kubectl -n promo get deploy promo -o jsonpath='{.spec.template.spec.containers[0].envFrom}'; echo
```

**Fix**: `kubectl -n promo rollout restart deploy/promo` (a new ReplicaSet, a rolling replacement).

**Interview notes**
- env/envFrom: read at container start. Volume-mounted ConfigMaps: updated in place by the kubelet
  (eventually, ~1 min), but only if the app re-reads the file, and **never** with `subPath` (C02).
- Roll on change automatically: a hash of the config in a pod-template annotation (Helm's
  `checksum/config`, Kustomize `configMapGenerator` name suffixes), or a controller such as Stakater Reloader.
- Immutable, versioned ConfigMaps (`promo-config-v2`) make every change an explicit rollout, and a rollback
  too (C06).
