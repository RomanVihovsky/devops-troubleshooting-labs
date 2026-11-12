## Hint 1
`kubectl -n shop describe pod <api pod>` → which Secret is missing? `kubectl -n shop get externalsecret
shop-secrets -o yaml` → `status.conditions`.

## Hint 2
`bao kv list -mount=secret /` and `bao kv get -mount=secret shop` (`eval "$(./lab env)"`). Compare with the
`remoteRef.key` the ExternalSecret uses - and where that value comes from in Git.

## Hint 3
`secret.externalSecret.remoteKey` in `envs/shop/values.yaml` must be `shop`. Push, refresh shop; ESO
recreates the Secret (`kubectl -n shop annotate externalsecret shop-secrets force-sync=$(date +%s)
--overwrite` speeds it up); pods in CreateContainerConfigError start by themselves.
