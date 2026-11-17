# V06: volumeClaimTemplates are immutable; the PVCs themselves can be expanded (nfs allows it)
kns metrics
ka -f tsdb.yaml
wait_rollout metrics sts/tsdb 240
for i in 0 1; do
  kx -n metrics exec "tsdb-$i" -- labapp get -X PUT -d "series-of-tsdb-$i" "http://localhost:8080/kv/marker" >/dev/null
done
remember v06_uids "$(kx -n metrics get pvc data-tsdb-0 data-tsdb-1 -o jsonpath='{.items[*].metadata.uid}')"
# the student's first attempt, as the ticket describes it: must be rejected on this version
try=$(mktemp); sed 's/storage: 1Gi/storage: 2Gi/' tsdb.yaml > "$try"
! kx apply -f "$try" >/dev/null 2>&1 || { rm -f "$try"; die "this cluster accepted a volumeClaimTemplates change"; }
rm -f "$try"
