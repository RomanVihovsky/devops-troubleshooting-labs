# Y04: OpenBao role prod is bound to ServiceAccount "default"; prod's SecretStore logs in as eso-reader
kns prod
bx kv put -mount=secret prod/app api_key="$(rand)" >/dev/null
printf 'path "secret/data/prod/*" { capabilities = ["read"] }\n' | bx policy write prod-read - >/dev/null
bx write auth/kubernetes/role/prod bound_service_account_names=default bound_service_account_namespaces=prod \
  token_policies=prod-read audience=openbao token_ttl=1h >/dev/null
kx -n prod create configmap lab-ca --from-file=ca.crt="$CA_DIR/ca.crt" --dry-run=client -o yaml | ka -f -
retry 120 ka -f store.yaml || die "store not accepted"
ka -f api.yaml
denied() { kx -n prod get secretstore openbao -o json | jq -e '[.status.conditions[]? | select(.type == "Ready" and .status == "False")] | length > 0' >/dev/null \
           && ! kx -n prod get secret app-secrets >/dev/null 2>&1; }
retry 120 denied || die "the store is not failing"
