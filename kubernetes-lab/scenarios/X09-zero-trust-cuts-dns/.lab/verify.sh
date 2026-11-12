conn() { kx -n shop exec "deploy/$1" -- python3 -c "import socket; socket.create_connection(('$2', $3), 3)" >/dev/null 2>&1; }
blocked() { ! conn "$@"; }
unchanged() {
  [ "$(kx -n shop get networkpolicy default-deny -o json 2>/dev/null | jq -c '[.spec.podSelector, .spec.policyTypes, (.spec.ingress // []), (.spec.egress // [])]')" = '[{},["Ingress","Egress"],[],[]]' ] \
    && [ "$(kx -n external-secrets get networkpolicy default-deny-egress -o json 2>/dev/null | jq -c '[.spec.podSelector, .spec.policyTypes, (.spec.egress // [])]')" = '[{},["Egress"],[]]' ]
}
T0=$(date -u +%FT%TZ)
eso_refresh() {
  kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s%N)" --overwrite >/dev/null 2>&1 || return 1
  refreshed() { local r; r=$(kx -n shop get externalsecret shop-secrets -o jsonpath='{.status.refreshTime}' 2>/dev/null)
    [ -n "$r" ] && [[ ! "$r" < "$T0" ]] && es_ready shop shop-secrets; }
  retry 60 refreshed
}
check "security's default-deny policies are unchanged" unchanged
check_eventually 120 "shop.lab end to end (traefik -> frontend -> api -> db)" shop_ok
check "ESO refreshes shop-secrets from OpenBao" eso_refresh
check "frontend -> postgres:5432 blocked" blocked frontend postgres 5432
check "frontend -> redis:6379 blocked" blocked frontend redis 6379
check "api -> k8s-gw:22 blocked" blocked api 192.168.56.20 22
verdict
