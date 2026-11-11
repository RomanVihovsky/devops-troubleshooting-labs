up_ok() { [ "$(http_code notify http://notifier.notify.svc:8080/upstream)" = 200 ]; }
# the token reaches notifier from Secret api-token (env secretKeyRef or a mounted volume), not as a literal
from_secret() { kx -n notify get deploy notifier -o json | jq -e '.spec.template.spec as $s
  | ([$s.containers[].env[]? | select(.name == "UPSTREAM_TOKEN" and .value != null)] | length == 0)
    and ((([$s.volumes[]? | select(.secret.secretName == "api-token")] | length) > 0)
         or (([$s.containers[].env[]? | select(.valueFrom.secretKeyRef.name == "api-token")] | length) > 0))' >/dev/null; }
check_eventually 120 "notifier -> upstream answers 200" up_ok
check "the token comes from Secret api-token (no literal)" from_secret
if [ -z "${LAB_EXPECT_FAIL:-}" ] && up_ok; then
  bx kv put -mount=secret notify/api token="$(rand)" >/dev/null
  kx -n notify annotate externalsecret api-token force-sync="$(date +%s)" --overwrite >/dev/null
  rotated() { [ "$(kx -n notify get secret api-token -o jsonpath='{.data.token}' | base64 -d)" = "$(bx kv get -mount=secret -field=token notify/api)" ]; }
  check_eventually 90 "another rotation in OpenBao reached Secret api-token" rotated
  sleep 20   # let upstream (mounted file) see the new token first
  check_eventually 180 "...and notifier still gets 200 without a restart" up_ok
fi
verdict
