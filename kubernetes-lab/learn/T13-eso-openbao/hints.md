## Hint 1
```
bao kv put -mount=secret t13/db username=app password=s3cr3t
printf 'path "secret/data/t13/*" { capabilities = ["read"] }\n' | bao policy write t13-read -
bao write auth/kubernetes/role/t13 bound_service_account_names=t13-reader \
  bound_service_account_namespaces=t13 token_policies=t13-read audience=openbao token_ttl=1h
```
kv-v2 puts the data under `secret/data/...` (and metadata under `secret/metadata/...`): policies use those
paths, the CLI hides it.

## Hint 2
`kubectl -n t13 create configmap lab-ca --from-file=ca.crt=$BAO_CACERT`. In the SecretStore:
`provider.vault: {server: https://bao.lab:8200, path: secret, version: v2, caProvider: {type: ConfigMap,
name: lab-ca, key: ca.crt}, auth: {kubernetes: {mountPath: kubernetes, role: t13, serviceAccountRef: {name:
t13-reader, audiences: [openbao]}}}}`. A namespaced store may not point its caProvider at another namespace.

## Hint 3
`kubectl -n t13 describe secretstore openbao` / `externalsecret db-creds` show the error ESO got from
OpenBao (permission denied = policy/role, x509 = CA, "audience" = token audience). Test the policy:
`bao token create -policy=t13-read -ttl=5m`, then `BAO_TOKEN=<it> bao kv get -mount=secret shop` must fail.
