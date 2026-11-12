bx write auth/kubernetes/role/prod bound_service_account_names=eso-reader bound_service_account_namespaces=prod \
  token_policies=prod-read audience=openbao token_ttl=1h >/dev/null
kx -n prod annotate secretstore openbao force-sync="$(date +%s)" --overwrite >/dev/null
kx -n prod annotate externalsecret app-secrets force-sync="$(date +%s)" --overwrite >/dev/null
retry 120 es_ready prod app-secrets || true
