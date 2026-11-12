# Every ExternalSecret stopped refreshing after the CA bundle cleanup
**INC-2364** · P2 · Reporter: platform team

During yesterday's "CA bundle cleanup" someone re-created the ConfigMap `external-secrets/lab-ca` from a file
in our backups ("it's the lab CA, same name"). Since then the ClusterSecretStore `openbao` says
*x509: certificate signed by unknown authority*, and `shop/shop-secrets` no longer refreshes. The current
lab CA is the one the `bao` CLI trusts (`$BAO_CACERT` after `eval "$(./lab env)"`). TLS verification stays
on.

**Test**: ClusterSecretStore `openbao` Ready over `https://` with its `caProvider` still the ConfigMap
`external-secrets/lab-ca`, which now holds the current lab CA; `shop-secrets` refreshes again (Ready, synced
after a forced refresh); shop.lab works end to end.
