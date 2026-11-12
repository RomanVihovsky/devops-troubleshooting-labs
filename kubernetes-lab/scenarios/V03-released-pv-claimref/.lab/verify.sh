same_pv() { [ "$(kx get pv orders-archive -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall v03_pv)" ]; }
bound_to() { [ "$(kx -n archive get pvc archive -o jsonpath='{.status.phase}/{.spec.volumeName}' 2>/dev/null)" = Bound/orders-archive ]; }
reads() { [ "$(kx -n archive exec reader -- cat /data/index.txt 2>/dev/null)" = "orders 2016-2026" ]; }
check "PV orders-archive is the same object (not re-created)" same_pv
check_eventually 60 "PVC archive Bound to orders-archive" bound_to
check_eventually 90 "reader sees the archive" reads
verdict
