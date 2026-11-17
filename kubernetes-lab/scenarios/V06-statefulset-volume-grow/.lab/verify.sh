same_pvcs() { [ "$(kx -n metrics get pvc data-tsdb-0 data-tsdb-1 -o jsonpath='{.items[*].metadata.uid}' 2>/dev/null)" = "$(recall v06_uids)" ]; }
grown() {
  [ "$(kx -n metrics get pvc data-tsdb-0 data-tsdb-1 -o jsonpath='{range .items[*]}{.spec.resources.requests.storage}/{.status.capacity.storage} {end}' 2>/dev/null)" = "2Gi/2Gi 2Gi/2Gi " ]
}
template_2gi() { [ "$(kx -n metrics get sts tsdb -o jsonpath='{.spec.volumeClaimTemplates[0].spec.resources.requests.storage}' 2>/dev/null)" = 2Gi ]; }
ready() { [ "$(kx -n metrics get sts tsdb -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 2 ]; }
data_kept() {
  local i; for i in 0 1; do
    [ "$(kx -n metrics exec "tsdb-$i" -- labapp get http://localhost:8080/kv/marker 2>/dev/null)" = "series-of-tsdb-$i" ] || return 1
  done
}
check "PVCs data-tsdb-0/1 are the original volumes" same_pvcs
check_eventually 120 "both PVCs request and have 2Gi" grown
check "the StatefulSet template asks for 2Gi" template_2gi
check_eventually 120 "tsdb: 2 Ready pods" ready
check "each pod still returns its data" data_kept
verdict
