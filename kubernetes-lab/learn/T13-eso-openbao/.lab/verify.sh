store_ok() { [ "$(kx -n t13 get secretstore openbao -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
store_ca() { [ "$(kx -n t13 get secretstore openbao -o jsonpath='{.spec.provider.vault.caProvider.name}{.spec.provider.vault.caBundle}' 2>/dev/null)" != "" ]; }
es_ok() { es_ready t13 db-creds; }
bao_pw() { bx kv get -mount=secret -field=password t13/db 2>/dev/null; }
k8s_pw() { kx -n t13 get secret db-creds -o jsonpath='{.data.password}' 2>/dev/null | base64 -d 2>/dev/null; }
synced() { local b; b=$(bao_pw); [ -n "$b" ] && [ "$(k8s_pw)" = "$b" ] && [ "$(kx -n t13 get secret db-creds -o jsonpath='{.data.username}' | base64 -d)" = app ]; }
rotated() { [ "$(bx kv metadata get -mount=secret -format=json t13/db 2>/dev/null | jq -r .data.current_version)" -ge 2 ] 2>/dev/null; }
role_ok() {
  bx read -format=json auth/kubernetes/role/t13 2>/dev/null | jq -e '.data
    | (.bound_service_account_names == ["t13-reader"]) and (.bound_service_account_namespaces == ["t13"])
    and (.token_policies == ["t13-read"])' >/dev/null
}
least_privilege() {
  local t ok=1; t=$(bx token create -policy=t13-read -ttl=2m -field=token 2>/dev/null) || return 1
  BAO_ADDR=$BAO_URL BAO_CACERT=$CA_DIR/ca.crt BAO_TOKEN=$t "$BIN_DIR/bao" kv get -mount=secret t13/db >/dev/null 2>&1 || ok=0
  BAO_ADDR=$BAO_URL BAO_CACERT=$CA_DIR/ca.crt BAO_TOKEN=$t "$BIN_DIR/bao" kv get -mount=secret shop >/dev/null 2>&1 && ok=0
  bx token revoke "$t" >/dev/null 2>&1
  [ $ok = 1 ]
}
check_eventually 60 "SecretStore t13/openbao Ready" store_ok
check "the SecretStore trusts the lab CA (caProvider/caBundle)" store_ca
check_eventually 60 "ExternalSecret t13/db-creds Ready" es_ok
check_eventually 60 "db-creds = OpenBao's current secret/t13/db (username app)" synced
check "the password was rotated at least once (kv version >= 2)" rotated
check "role t13: only t13/t13-reader, policy t13-read" role_ok
check "policy t13-read reads secret/t13/db but not secret/shop" least_privilege
verdict
