# Secrets stopped syncing after last night's gw maintenance
**INC-2514** · P1 · Reporter: on-call

Since the maintenance run on `k8s-gw` (config management "repaired missing files" and restarted services) every
ExternalSecret fails, and the ClusterSecretStore `openbao` is not Ready. The OpenBao service is *running*. The
maintenance run took a backup of `/etc/openbao` first (`/var/backups/openbao/` on `k8s-gw`). Bring the secret
store back **with its data** - re-initialising OpenBao is not an option.

**Test**: OpenBao is unsealed, with the data it had (the `shop` secrets unchanged); the ClusterSecretStore is
Ready; `shop/shop-secrets` refreshes again (after a forced sync); shop.lab works end to end.
