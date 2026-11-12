# soft spreading (ScheduleAnyway, preferred anti-affinity) may give 3/1/1 - fine, as long as every worker has one
spread() { local on; on=$(kx -n gateway get pods -l app=gateway -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | sort -u | paste -sd' ')
  [ "$on" = "k8s-w1 k8s-w2 k8s-w3" ]; }
check_eventually 120 "5 gateway pods Running + Ready" deploy_ready gateway gateway 5
check "spread over all 3 workers" spread
verdict
