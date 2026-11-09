bx kv put -mount=secret t13/db username=app password="$(rand)" >/dev/null
printf 'path "secret/data/t13/*" { capabilities = ["read"] }\n' | bx policy write t13-read - >/dev/null
bx write auth/kubernetes/role/t13 bound_service_account_names=t13-reader bound_service_account_namespaces=t13 \
  token_policies=t13-read audience=openbao token_ttl=1h >/dev/null
kx -n t13 create configmap lab-ca --from-file=ca.crt="$CA_DIR/ca.crt" >/dev/null
python3 - <<'PY'
import yaml
docs = [d for d in yaml.safe_load_all(open("store.yaml")) if d]
for d in docs:
    if d["kind"] == "SecretStore":
        v = d["spec"]["provider"]["vault"]
        v["caProvider"] = {"type": "ConfigMap", "name": "lab-ca", "key": "ca.crt"}
        v["auth"]["kubernetes"]["role"] = "t13"
        v["auth"]["kubernetes"]["serviceAccountRef"]["name"] = "t13-reader"
    if d["kind"] == "ExternalSecret":
        d["spec"]["data"] = [{"secretKey": k, "remoteRef": {"key": "t13/db", "property": k}} for k in ("username", "password")]
yaml.safe_dump_all(docs, open("store.yaml", "w"), sort_keys=False)
PY
retry 120 kx apply -f store.yaml >/dev/null
retry 120 es_ready t13 db-creds || die "db-creds not Ready"
bx kv put -mount=secret t13/db username=app password="$(rand)" >/dev/null      # rotation
want=$(bx kv get -mount=secret -field=password t13/db)
synced() { [ "$(kx -n t13 get secret db-creds -o jsonpath='{.data.password}' | base64 -d)" = "$want" ]; }
retry 90 synced || true
