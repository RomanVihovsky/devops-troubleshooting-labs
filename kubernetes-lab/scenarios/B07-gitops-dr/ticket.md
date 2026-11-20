# DR drill gone wrong: Argo CD, Sealed Secrets and OpenBao all broken
**INC-2960** · P1 · Reporter: platform team

The disaster-recovery drill "rebuilt" the platform pieces by hand, and now nothing reconciles: Argo CD shows every app
in an error state, `demo` lost its credentials, `shop`'s secrets don't sync. What the drill notes say: OpenBao was
restarted "with a fresh seal key" (the old `/etc/openbao` was backed up to `/var/backups/openbao/` on `k8s-gw`); Argo
CD's repository credentials were "recreated later" (they're in OpenBao at `secret/ci/gitea-argocd`, user `argocd`);
the Sealed Secrets controller was reinstalled without its key (the backup is `.state/sealed-secrets-key.yaml` on the
desktop); the root app was re-applied "from the old runbook". Git is the source of truth - nothing in Git may change,
nothing may be re-sealed.

**Test**: OpenBao is unsealed; the Argo CD apps `lab-apps`, `demo` and `shop` are Synced and Healthy from branch
`main`; every SealedSecret is Synced with the original key; the ExternalSecrets are Ready; `demo.lab` and `shop.lab`
work end to end; Git `main` is unchanged.
