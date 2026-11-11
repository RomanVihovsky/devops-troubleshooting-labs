api_up() { [ "$(kx get --raw /readyz 2>/dev/null)" = ok ]; }
mirror_ready() { [ "$(kx -n kube-system get pod "kube-apiserver-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
flags() { nx "$CP" "grep -q -- '--audit-policy-file=/etc/kubernetes/audit/policy.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml \
                    && grep -q -- '--audit-log-path=/var/log/kubernetes/audit/audit.log' /etc/kubernetes/manifests/kube-apiserver.yaml \
                    && grep -q -- '--audit-log-maxage=' /etc/kubernetes/manifests/kube-apiserver.yaml" </dev/null; }
manifests4() { [ "$(nx "$CP" 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]; }
# a Secret read now -> an event on the node's disk, newer than this check
fresh_event() {
  local t; t=$(nx "$CP" "date -u +%FT%T" </dev/null)   # the node's clock: the events carry its time
  kx -n shop get secret shop-secrets >/dev/null 2>&1 || return 1
  sleep 3
  nx "$CP" "tail -n 400 /var/log/kubernetes/audit/audit.log 2>/dev/null" </dev/null \
    | jq -e --arg t "$t" 'select(.objectRef.resource == "secrets" and .objectRef.name == "shop-secrets" and .requestReceivedTimestamp >= $t)' >/dev/null
}
check_eventually 180 "the API answers (/readyz)" api_up
check_eventually 120 "kube-apiserver mirror pod Ready" mirror_ready
check "audit flags kept (policy, log path, retention)" flags
check_eventually 60 "reading a Secret writes an event to /var/log/kubernetes/audit/audit.log on $CP" fresh_event
check "only the 4 control-plane manifests" manifests4
verdict
