# Y04 - an OpenBao role bound to the wrong ServiceAccount

**Root cause**: the OpenBao kubernetes-auth role `prod` was created with
`bound_service_account_names=default`. The SecretStore authenticates with a token of ServiceAccount
`eso-reader` (`serviceAccountRef`). OpenBao validated the token (TokenReview) and then refused it: the name
was not in the role's bound list. *permission denied*, so no Secret and no `api` pods.

**Diagnosis**
```
kubectl -n prod describe secretstore openbao        # ... permission denied (auth/kubernetes/login)
bao read auth/kubernetes/role/prod                  # bound_service_account_names [default]
kubectl -n prod get secretstore openbao -o jsonpath='{.spec.provider.vault.auth.kubernetes}'
```

**Fix**: bind the role to the ServiceAccount the store really uses:
```
bao write auth/kubernetes/role/prod bound_service_account_names=eso-reader bound_service_account_namespaces=prod \
  token_policies=prod-read audience=openbao token_ttl=1h
kubectl -n prod annotate externalsecret app-secrets force-sync=$(date +%s) --overwrite
```

**Interview notes**
- Kubernetes auth = the client sends a ServiceAccount JWT; OpenBao calls the TokenReview API (with its
  reviewer token) and then matches the SA name, namespace and audience against the role. Every one of these
  can fail: wrong SA, wrong namespace, `audience` mismatch, an expired reviewer token, or the cluster CA.
- `bound_service_account_names=*` "works" and turns every ServiceAccount in the namespace (or every
  namespace) into a reader. One role per workload identity, least-privilege policy.
- A `SecretStore` (namespaced) vs a `ClusterSecretStore`: a namespaced store keeps a team's credentials and
  blast radius in its namespace. A ClusterSecretStore with one powerful role is convenient, and dangerous.
- ESO re-validates a store periodically. Annotate to force it, and read the store's conditions before the
  ExternalSecret's.
