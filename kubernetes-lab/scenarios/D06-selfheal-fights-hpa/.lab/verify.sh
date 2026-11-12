# quiet <app> <seconds>: Synced now, no sync operation started in the last <seconds> (the flapping shows up there),
# and still Synced after watching (3 s in selftest's broken pass, the look-back still applies)
quiet() {
  local t=$2 since; since=$(date -u -d "-$2 seconds" +%FT%TZ)
  [ "$(kx -n argocd get application "$1" -o jsonpath='{.status.sync.status}')" = Synced ] || return 1
  [ "$(kx -n argocd get application "$1" -o jsonpath='{.status.operationState.startedAt}')" \< "$since" ] || return 1
  [ -n "${LAB_EXPECT_FAIL:-}" ] && t=3
  sleep "$t"; [ "$(kx -n argocd get application "$1" -o jsonpath='{.status.sync.status}')" = Synced ]
}
hpas() { kx -n demo get hpa -o json | jq -r '.items[] | select(.spec.scaleTargetRef.kind == "Deployment" and .spec.scaleTargetRef.name == "demo") | "\(.metadata.name) \(.spec.minReplicas) \(.status.desiredReplicas)"'; }
one_hpa() { [ "$(hpas | wc -l)" = 1 ] && [ "$(hpas | awk '{print $2}')" -ge 3 ]; }
follows() { [ "$(kx -n demo get deploy demo -o jsonpath='{.spec.replicas}')" = "$(hpas | awk 'NR == 1 {print $3}')" ]; }
# Git doesn't render replicas (the last apply of Argo CD has none), or the app ignores them and respects that
not_pinned() {
  local la app
  la=$(kx -n demo get deploy demo -o jsonpath='{.metadata.annotations.kubectl\.kubernetes\.io/last-applied-configuration}')
  [ -n "$la" ] && ! jq -e '.spec | has("replicas")' <<<"$la" >/dev/null && return 0
  app=$(kx -n argocd get application demo -o json)
  jq -e '([.spec.ignoreDifferences[]? | select(.kind == "Deployment" and ((.jsonPointers // []) | index("/spec/replicas")))] | length > 0)
         and ((.spec.syncPolicy.syncOptions // []) | index("RespectIgnoreDifferences=true"))' <<<"$app" >/dev/null
}
check_eventually 240 "demo Synced, no sync operation for 120 s" quiet demo 120
check "exactly one HPA scales deploy/demo, minReplicas >= 3" one_hpa
check_eventually 60 "the Deployment's replicas follow the HPA" follows
check "Git doesn't pin replicas (or ignoreDifferences + RespectIgnoreDifferences)" not_pinned
check_eventually 60 "demo Synced + Healthy" argo_app_ok demo
verdict
