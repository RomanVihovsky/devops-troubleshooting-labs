secret_kept() { [ "$(kx -n ledger get secret ledger-db -o jsonpath='{.data.passwd}' 2>/dev/null | base64 -d)" = "$(recall p06_pw)" ]; }
check_eventually 120 "ledger rollout complete, all replicas Ready" deploy_ready ledger ledger
check "Secret ledger-db still holds the DBA's value (key passwd)" secret_kept
verdict
