# Y07: a token rotated in OpenBao reaches the Secret (ESO) and upstream (mounted file), but not notifier (env var)
kns notify
bx kv put -mount=secret notify/api token="$(rand)" >/dev/null
printf 'path "secret/data/notify/*" { capabilities = ["read"] }\n' | bx policy write notify-read - >/dev/null
bx write auth/kubernetes/role/notify bound_service_account_names=eso bound_service_account_namespaces=notify \
  token_policies=notify-read audience=openbao token_ttl=1h >/dev/null
kx -n notify create configmap lab-ca --from-file=ca.crt="$CA_DIR/ca.crt" --dry-run=client -o yaml | ka -f -
retry 120 ka -f store.yaml || die "store not accepted"
retry 120 es_ready notify api-token || die "api-token never synced"
ka -f upstream.yaml; ka -f notifier.yaml
wait_rollout notify deploy/upstream; wait_rollout notify deploy/notifier
up_ok() { [ "$(http_code notify http://notifier.notify.svc:8080/upstream)" = 200 ]; }
retry 60 up_ok || die "notifier -> upstream does not work before the rotation"
# the rotation
bx kv put -mount=secret notify/api token="$(rand)" >/dev/null
kx -n notify annotate externalsecret api-token force-sync="$(date +%s)" --overwrite >/dev/null
up_401() { [ "$(http_code notify http://notifier.notify.svc:8080/upstream)" = 502 ]; }
retry 180 up_401 || die "notifier still works after the rotation"
