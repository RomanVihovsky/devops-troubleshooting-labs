# conn <ns> <workload> <host> <port>: a TCP connect from inside a real pod (labapp has python, Argo CD bash)
conn() {
  case $2 in
    deploy/frontend|deploy/api) kx -n "$1" exec "$2" -- python3 -c "import socket; socket.create_connection(('$3', $4), 3)" >/dev/null 2>&1 ;;
    *) kx -n "$1" exec "$2" -- timeout 4 bash -c "</dev/tcp/$3/$4" >/dev/null 2>&1 ;;
  esac
}
blocked() { ! conn "$@"; }
egress_all() {
  kx -n "$1" get networkpolicy -o json 2>/dev/null | jq -e '[.items[] | select(.spec.podSelector == {} and (.spec.policyTypes | index("Egress")))] | length > 0' >/dev/null
}
deny_all() {
  kx -n shop get networkpolicy -o json 2>/dev/null | jq -e '[.items[] | select(.spec.podSelector == {} and (.spec.policyTypes | index("Ingress")) and (.spec.policyTypes | index("Egress")) and ((.spec.ingress // []) | length == 0))] | length > 0' >/dev/null
}
T0=$(date -u +%FT%TZ)
eso_refresh() {
  kx -n shop annotate externalsecret shop-secrets force-sync="$(date +%s%N)" --overwrite >/dev/null 2>&1 || return 1
  refreshed() { local r; r=$(kx -n shop get externalsecret shop-secrets -o jsonpath='{.status.refreshTime}' 2>/dev/null)
    [ -n "$r" ] && [[ ! "$r" < "$T0" ]] && es_ready shop shop-secrets; }
  retry 60 refreshed
}
argo_reads_git() {
  argo_refresh shop || return 1
  fresh() { local r; r=$(kx -n argocd get application shop -o jsonpath='{.status.reconciledAt}' 2>/dev/null)
    [ -n "$r" ] && [[ ! "$r" < "$T0" ]] && [ -z "$(kx -n argocd get application shop -o jsonpath='{.status.conditions[?(@.type=="ComparisonError")].message}')" ] \
      && argo_app_ok shop; }
  retry 90 fresh
}
check "shop: a default-deny policy (all pods, in + out)" deny_all
check_eventually 60 "frontend -> api:8080 open" conn shop deploy/frontend api 8080
check_eventually 60 "api -> postgres:5432 open" conn shop deploy/api postgres 5432
check_eventually 60 "api -> redis:6379 open" conn shop deploy/api redis 6379
check "frontend -> postgres:5432 blocked" blocked shop deploy/frontend postgres 5432
check "frontend -> redis:6379 blocked" blocked shop deploy/frontend redis 6379
check "api -> k8s-gw:22 blocked" blocked shop deploy/api 192.168.56.20 22
check_eventually 90 "shop.lab end to end (traefik -> frontend -> api -> db)" shop_ok
check "external-secrets: an egress policy covers every pod" egress_all external-secrets
check "ESO refreshes shop-secrets from OpenBao" eso_refresh
check "argocd: an egress policy covers every pod" egress_all argocd
check_eventually 30 "argocd repo-server -> Gitea (192.168.56.20:3000) open" conn argocd deploy/argocd-repo-server 192.168.56.20 3000
check "argocd repo-server -> k8s-gw:22 blocked" blocked argocd deploy/argocd-repo-server 192.168.56.20 22
check "Argo CD reads Git (hard refresh of shop, no ComparisonError)" argo_reads_git
verdict
