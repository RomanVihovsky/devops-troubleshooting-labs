## Hint 1
`kubectl -n prod describe secretstore openbao` and `kubectl -n prod describe externalsecret app-secrets`:
which login fails? Then look at the OpenBao side: `bao read auth/kubernetes/role/prod`.

## Hint 2
OpenBao's kubernetes auth checks the ServiceAccount *token* it receives against the role's
`bound_service_account_names` / `bound_service_account_namespaces`. Which ServiceAccount does the store send,
and which one does the role allow?

## Hint 3
`bao write auth/kubernetes/role/prod bound_service_account_names=eso-reader bound_service_account_namespaces=prod
token_policies=prod-read audience=openbao token_ttl=1h`, then nudge ESO:
`kubectl -n prod annotate externalsecret app-secrets force-sync=$(date +%s) --overwrite`.
