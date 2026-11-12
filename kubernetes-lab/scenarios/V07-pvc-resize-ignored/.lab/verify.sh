cap2() { [ "$(kx -n archive get pvc archive-data -o jsonpath='{.status.capacity.storage}')" = 2Gi ]; }
same_pv() { [ "$(kx -n archive get pvc archive-data -o jsonpath='{.spec.volumeName}')" = "$(recall v07_pv)" ]; }
data_kept() { [ "$(kx -n archive exec deploy/archive -- labapp get http://localhost:8080/kv/report-2026 2>/dev/null)" = "$(recall v07_value)" ]; }
check_eventually 120 "archive-data capacity 2Gi" cap2
check "the same volume as before (not a new claim)" same_pv
check_eventually 120 "archive Ready" deploy_ready archive archive 1
check "the data written before the resize is still there" data_kept
verdict
