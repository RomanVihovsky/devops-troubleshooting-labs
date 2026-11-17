zones() {   # "<zone-a count> <zone-b count>" of the Ready search-api pods
  local n a=0 b=0
  while read -r _ n; do
    [ -n "$n" ] || continue
    case $(kx get node "$n" -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}') in zone-a) a=$((a + 1)) ;; zone-b) b=$((b + 1)) ;; esac
  done < <(kx -n search get pods -l app=search-api -o json | jq -r '.items[] | select(.metadata.deletionTimestamp == null)
             | select(any(.status.conditions[]?; .type == "Ready" and .status == "True")) | "\(.metadata.name) \(.spec.nodeName)"')
  echo "$a $b"
}
even() { [ "$(zones)" = "2 2" ]; }
spread_kept() {
  kx -n search get deploy search-api -o json | jq -e '[.spec.template.spec.topologySpreadConstraints[]? | select(.topologyKey == "topology.kubernetes.io/zone" and .maxSkew <= 1)] | length > 0' >/dev/null
}
check_eventually 120 "search-api: 4 Ready replicas" deploy_ready search search-api 4
check_eventually 60 "2 replicas in zone-a and 2 in zone-b" even
check "a zone topology spread constraint (maxSkew 1) is still in place" spread_kept
verdict
