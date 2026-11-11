want=$(bx kv get -mount=secret -field=api_key prod/app 2>/dev/null)
store_ok() { [ "$(kx -n prod get secretstore openbao -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
synced() { es_ready prod app-secrets && [ "$(kx -n prod get secret app-secrets -o jsonpath='{.data.api_key}' | base64 -d)" = "$want" ]; }
role_right() { bx read -format=json auth/kubernetes/role/prod | jq -e '.data
  | .bound_service_account_names == ["eso-reader"] and .bound_service_account_namespaces == ["prod"]
    and ((.token_policies // []) - ["default"]) == ["prod-read"]' >/dev/null; }
store_sa() { [ "$(kx -n prod get secretstore openbao -o jsonpath='{.spec.provider.vault.auth.kubernetes.serviceAccountRef.name}')" = eso-reader ]; }
check_eventually 120 "SecretStore prod/openbao Ready" store_ok
check_eventually 120 "ExternalSecret app-secrets Ready, Secret holds secret/prod/app api_key" synced
check_eventually 120 "api: 2 Ready pods" deploy_ready prod api 2
check "role prod bound to exactly prod/eso-reader, policy prod-read only" role_right
check "the store still logs in as eso-reader" store_sa
verdict
