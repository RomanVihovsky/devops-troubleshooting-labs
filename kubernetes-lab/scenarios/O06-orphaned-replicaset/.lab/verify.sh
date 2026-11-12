no_rs() { [ -z "$(kx -n retired get rs -l app=oldapp -o name 2>/dev/null)" ]; }
no_pods() { [ -z "$(kx -n retired get pods -l app=oldapp -o name 2>/dev/null)" ]; }
check_eventually 60 "no ReplicaSet of oldapp" no_rs
check_eventually 60 "no pod of oldapp" no_pods
check "keeper still runs" deploy_ready retired keeper 1
verdict
