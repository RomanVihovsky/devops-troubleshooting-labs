# Helm charts

| Chart | What |
|---|---|
| `labapp/` | one [labapp](../apps/labapp/README.md) service: Deployment, Service (+ headless), Ingress / HTTPRoute, ConfigMap, ServiceAccount (+ RBAC), HPA, PDB, NetworkPolicy, PVC, migration hook Job, Secret source |
| `shop/` | umbrella: `frontend` + `api` (both labapp, aliased), vendored `redis` and `postgres` subcharts, one shared Secret |

Both work offline: images come from `registry.lab:5000/lab/*` and nothing is fetched at render time.

```bash
helm dependency build charts/shop     # packs ../labapp into charts/shop/charts/ (gitignored); Argo CD does this itself
helm lint charts/labapp charts/shop
helm template t charts/labapp -f charts/labapp/ci/hpa-values.yaml
helm template shop charts/shop -n shop | kubectl apply -n shop --dry-run=server -f -
```

`ci/*.yaml` in each chart are the tested value combinations (ingress vs HTTPRoute, every secret source,
HPA, kitchen sink). Every one renders, passes `kubectl apply --dry-run=server --validate=strict` (CRD kinds
aside) and raises no PodSecurity `restricted` warnings.

## labapp values in one breath

- `app.*` → labapp settings (one env var each, listed in `values.yaml`), stored in the `<fullname>` ConfigMap
  and consumed with `envFrom`. `config.rollOnChange` adds checksum annotations (ConfigMap, SealedSecret ciphertext) so changes in Git
  roll pods; an ExternalSecret changes outside Git, so use `secrets.mountAsFiles` (labapp re-reads files).
  `app.settings` passes any other setting; `app.extraEnv` adds raw env entries.
- `secrets.source`: `none` | `existingSecret` | `sealedSecret` (`encryptedData` passed through, `scope`) |
  `externalSecret` (`storeRef` → ClusterSecretStore `openbao`, `remoteKey` + per-key property or
  `{key, property}`, `creationPolicy`). `secrets.env` maps a setting to a key in that Secret (one
  `secretKeyRef` each); `secrets.mountAsFiles` mounts it instead and sets `<SETTING>_FILE`.
- `app.credentialsSecret` makes labapp read a Secret through the API; `rbac.create` then renders a Role
  limited to that one `resourceNames` entry.
- Routing: `ingress` (class `traefik`) and/or `httpRoute` (parentRef `traefik-gateway` in namespace `traefik`).
- Pods are PSA-restricted by default: uid 10001, read-only rootfs (`/tmp` emptyDir), no capabilities.
- `autoscaling.enabled` drops `spec.replicas` (the HPA owns it). `migrations.hook` defaults to
  `post-install,post-upgrade` (Argo CD: PostSync); a `pre-*` hook runs before the ConfigMap/Secret exist.

## shop

```
frontend (/) --Bearer api-token--> api (/items) --> postgres (items table, AUTO_MIGRATE)
                                                \-> redis (view counter, requirepass)
```

- Service names are fixed (`frontend`, `api`, `redis`, `postgres`) via `fullnameOverride`.
- `secret.source` = `inline` (demo plain Secret, default) | `existingSecret` | `sealedSecret` | `externalSecret`
  (kv-v2 path `shop`, properties `postgres_password`, `redis_password`, `api_token`). The subcharts read
  `shop-secrets`; rename it in all of them together.
- The api's `DATABASE_URL` carries no password; it gets `DATABASE_PASSWORD` from the `postgres-password` key,
  so the database password lives in exactly one place.
- `redis` and `postgres` are minimal vendored charts (`charts/shop/charts/`), declared without a repository.
