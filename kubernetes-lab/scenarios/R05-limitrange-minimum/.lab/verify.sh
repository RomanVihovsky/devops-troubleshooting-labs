lr_kept() { [ "$(kx -n team-b get limitrange standard -o jsonpath='{.spec}' 2>/dev/null)" = "$(recall r05_lr)" ]; }
check_eventually 120 "worker: 2 Ready pods" deploy_ready team-b worker 2
check "LimitRange standard unchanged" lr_kept
verdict
