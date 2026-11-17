want=$(printf '%s' "$(recall c07_token)" | base64 -w0)
exact() { [ "$(kx -n ledger get secret partner-token -o jsonpath='{.data.token}' 2>/dev/null)" = "$want" ]; }
gw_kept() { [ "$(kx -n ledger get secret gw-token -o jsonpath='{.data.token}' 2>/dev/null)" = "$want" ]; }
from_secret() {
  kx -n ledger get deploy ledger -o json | jq -e '.spec.template.spec.containers[0] as $c
    | ([$c.env[]? | select(.name == "UPSTREAM_TOKEN" and .value != null)] | length == 0)
    and ([.spec.template.spec.volumes[]? | select(.secret.secretName == "partner-token")] | length > 0)' >/dev/null
}
rejects() { [ "$(http_code ledger http://partner-gw.ledger.svc:8080/items)" = 401 ]; }
check "Secret partner-token holds exactly the gateway's token (no trailing newline)" exact
check "partner-gw's token is unchanged" gw_kept
check "ledger reads the token from Secret partner-token (no literal)" from_secret
check_eventually 150 "ledger: 2 Ready pods (upstream check passes)" deploy_ready ledger ledger 2
check "partner-gw still answers 401 without the token" rejects
verdict
