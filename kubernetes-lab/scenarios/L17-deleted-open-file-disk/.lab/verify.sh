unit_off() { ! nx k8s-w2 'systemctl is-active --quiet audit-spooler || systemctl is-enabled --quiet audit-spooler' </dev/null 2>/dev/null; }
var_ok() { [ "$(nx k8s-w2 "df --output=pcent /var | tail -1 | tr -dc 0-9" </dev/null 2>/dev/null)" -lt 80 ]; }
no_pressure() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="DiskPressure")].status}' 2>/dev/null)" = False ]; }
check "the audit spooler on w2 is stopped and disabled" unit_off
check_eventually 60 "/var on w2 is below 80 % used" var_ok
check_eventually 360 "k8s-w2 has no DiskPressure (the kubelet waits up to 5 min)" no_pressure
check_eventually 180 "audit-ui: 2 Ready pods on k8s-w2" deploy_ready audit audit-ui 2
verdict
