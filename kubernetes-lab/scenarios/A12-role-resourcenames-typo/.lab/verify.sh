SA=system:serviceaccount:payroll:syncer
job_done() { [ "$(kx -n payroll get job secret-sync -o jsonpath='{.status.succeeded}' 2>/dev/null)" = 1 ]; }
check_eventually 120 "Job secret-sync completed" job_done
check "syncer can get secret db-creds" can_i "$SA" get secret/db-creds -n payroll
check "syncer can NOT list secrets in payroll" not can_i "$SA" list secrets -n payroll
check "syncer can NOT get secret payroll-bank" not can_i "$SA" get secret/payroll-bank -n payroll
check "syncer can NOT get secrets in other namespaces" not can_i "$SA" get secrets -n kube-system
verdict
