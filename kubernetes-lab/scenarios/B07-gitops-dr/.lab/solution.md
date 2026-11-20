# B07 - GitOps DR: restore the roots of trust in dependency order

**Four broken roots**:
1. **OpenBao sealed** - its static seal key in `/etc/openbao/unseal.key` was replaced; restore the file from
   `/var/backups/openbao/*.tgz` on gw and restart (Y06). Everything secret-related depends on this.
2. **Argo CD repo credentials gone** - Secret `argocd/repo-gitops` (label `argocd.argoproj.io/secret-type:
   repository`, `type`, `url`, `username`, `password`). The password lives in OpenBao (`secret/ci/gitea-argocd`) -
   so step 1 first (D05).
3. **Root app on `master`** - the repo's branch is `main`; the app-of-apps can't resolve its revision, so no child app
   is managed (D11-style root app problems).
4. **Sealing key regenerated** - restore `.state/sealed-secrets-key.yaml`, restart the controller; SealedSecrets in
   Git decrypt again without re-sealing (Y02).

Then refresh **and sync** the apps - Argo CD never retries an automated sync that failed for the same revision, so
an app whose sync failed while the repo was unreachable stays failed until someone syncs it - and force-sync the
ExternalSecrets.

**Interview notes**
- A GitOps cluster's DR inventory: Git (source of truth), the repo credentials, the sealing key / KMS key, the secret
  store's unseal keys and data, the bootstrap (root app). Back up and test every one of them.
- Order by dependency, not by noise: the loudest symptom (Argo CD errors) depended on the quietest cause (a sealed
  vault).
