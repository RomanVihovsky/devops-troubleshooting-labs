# prod's API can't start: its secret never arrives
**INC-2360** · P1 · Reporter: team prod

We moved `prod` to its own SecretStore this morning (`workspace/Y04/store.yaml`): a dedicated ServiceAccount
`eso-reader`, OpenBao role `prod`, policy `prod-read` on `secret/prod/*`. The store says *permission denied*,
the ExternalSecret `app-secrets` never syncs, and the `api` pods wait for their Secret. Security insists:
the role stays bound to exactly that one ServiceAccount, and the store keeps using `eso-reader`.

**Test**: SecretStore `prod/openbao` Ready; ExternalSecret `app-secrets` Ready and Secret `app-secrets` holds
`secret/prod/app`'s `api_key`; `api` Ready; OpenBao role `prod` is bound to exactly `eso-reader` in `prod`
(no wildcards) with policy `prod-read` only; the store still authenticates as `eso-reader`.
