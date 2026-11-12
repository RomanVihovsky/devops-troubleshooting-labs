quota_ok() { [ "$(kx -n sandbox get resourcequota sandbox -o json | jq -c '.spec.hard')" = '{"pods":"5","requests.cpu":"2","requests.memory":"2Gi"}' ]; }
check_eventually 120 "notifier: 1 Ready pod" deploy_ready sandbox notifier 1
check "legacy: 2 Ready pods" deploy_ready sandbox legacy 2
check "the quota allows 5 pods, otherwise unchanged" quota_ok
verdict
