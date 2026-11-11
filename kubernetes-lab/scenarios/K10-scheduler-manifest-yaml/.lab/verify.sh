sched_ready() { [ "$(kx -n kube-system get pod "kube-scheduler-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
v2() { kx -n kube-system get pod "kube-scheduler-$CP" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null | grep -q -- '--v=2'; }
running() { [ "$(kx -n ops get pods -l app=reports --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)" = 2 ]; }
valid() { nx "$CP" "python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' /etc/kubernetes/manifests/kube-scheduler.yaml" </dev/null; }
manifests4() { [ "$(nx "$CP" 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]; }
check "the scheduler manifest is valid YAML" valid
check_eventually 120 "kube-scheduler mirror pod Ready" sched_ready
check "the scheduler runs with --v=2" v2
check_eventually 120 "ops/reports: 2 Running pods" running
check "only the 4 control-plane manifests" manifests4
verdict
