# T13 - solution and takeaways

```
bao kv put -mount=secret t13/db username=app password=...
printf 'path "secret/data/t13/*" { capabilities = ["read"] }\n' | bao policy write t13-read -
bao write auth/kubernetes/role/t13 bound_service_account_names=t13-reader \
  bound_service_account_namespaces=t13 token_policies=t13-read audience=openbao token_ttl=1h
kubectl -n t13 create configmap lab-ca --from-file=ca.crt=$BAO_CACERT
# store.yaml: caProvider {type: ConfigMap, name: lab-ca, key: ca.crt}; role t13; serviceAccountRef t13-reader
# ExternalSecret data: [{secretKey: username, remoteRef: {key: t13/db, property: username}}, ... password]
bao kv put -mount=secret t13/db username=app password=...new...     # rotation, ESO follows within 15 s
```

**Takeaways**
- The chain: ESO asks Kubernetes for a token of `t13-reader` (audience `openbao`) → logs in to OpenBao's
  kubernetes auth → OpenBao verifies the token with a TokenReview → issues a token with `t13-read` → ESO
  reads `secret/data/t13/db` → writes the Secret. Each arrow is an incident class (Y03-Y08).
- Least privilege = one role per namespace/team, bound to one ServiceAccount, with a policy for its own
  path. The shared ClusterSecretStore with a read-everything policy is convenient - and a blast radius.
- caProvider (or caBundle) instead of disabling TLS checks: the store must trust the CA that signed OpenBao.
- Rotation reaches the **Secret** on the next refresh; pods see env vars only after a restart (files are
  updated, Y07). kv-v2 keeps versions: `bao kv rollback` / `-version=`.
