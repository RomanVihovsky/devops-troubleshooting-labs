pv_of() { kx -n t05 get pvc "$1" -o jsonpath='{.spec.volumeName}' 2>/dev/null; }
pv_node() { kx get pv "$(pv_of local-data)" -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}' 2>/dev/null; }
local_ok() { [ "$(kx -n t05 get pvc local-data -o jsonpath='{.status.phase} {.spec.storageClassName}' 2>/dev/null)" = "Bound local-path" ]; }
local_retain() { [ "$(kx get pv "$(pv_of local-data)" -o jsonpath='{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null)" = Retain ]; }
rwx_ok() { [ "$(kx -n t05 get pvc shared -o jsonpath='{.status.phase} {.spec.storageClassName} {.spec.accessModes[*]}' 2>/dev/null)" = "Bound nfs ReadWriteMany" ]; }
writer_nodes() { kx -n t05 get pods -l app=writers --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' 2>/dev/null | sort -u; }
two_nodes() { [ "$(writer_nodes | grep -c .)" -ge 2 ]; }
log_from_both() {
  local p n; p=$(kx -n t05 get pods -l app=writers -o name 2>/dev/null | head -1); [ -n "$p" ] || return 1
  for n in $(writer_nodes); do kx -n t05 exec "$p" -- grep -q "^$n " /data/log || return 1; done
  [ "$(writer_nodes | grep -c .)" -ge 2 ]
}
snap_ready() { [ "$(kx -n t05 get volumesnapshot shared-snap -o jsonpath='{.status.readyToUse}' 2>/dev/null)" = true ]; }
restored_from_snap() { [ "$(kx -n t05 get pvc restored -o jsonpath='{.status.phase} {.spec.dataSource.kind}/{.spec.dataSource.name}' 2>/dev/null)" = "Bound VolumeSnapshot/shared-snap" ]; }
reader_sees_log() { kx -n t05 exec reader -- grep -qE '^k8s-[a-z0-9]+ [0-9]+' /data/log; }
check_eventually 60 "local-data Bound on local-path" local_ok
check "its PV is Retain" local_retain
check "answers: the node of the local-path PV" answered local_pv_node "$(pv_node)"
check_eventually 60 "shared: Bound, nfs, ReadWriteMany" rwx_ok
check_eventually 90 "writers run on 2 different nodes" two_nodes
check_eventually 30 "/data/log has lines from both writer nodes" log_from_both
check_eventually 90 "VolumeSnapshot shared-snap ready" snap_ready
check_eventually 90 "restored: Bound, from VolumeSnapshot shared-snap" restored_from_snap
check_eventually 90 "reader sees the log in the restored volume" reader_sees_log
verdict
