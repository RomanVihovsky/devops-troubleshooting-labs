flags() { nx "$CP" "grep -E -- '--(profiling|enable-admission-plugins|tls-cert-file|tls-private-key-file)=' /etc/kubernetes/manifests/kube-apiserver.yaml" </dev/null; }
api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
mirror_ready() { [ "$(kx -n kube-system get pod "kube-apiserver-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
profiling_off() { flags | grep -q -- '--profiling=false'; }
plugins_ok() { flags | grep -- '--enable-admission-plugins=' | grep -q NodeRestriction && ! flags | grep -q PodSecurityPolicy; }
certs_exist() {
  local f
  for f in $(flags | grep -oE -- '--tls-(cert|private-key)-file=[^ ]+' | cut -d= -f2); do
    nx "$CP" "test -s $f" </dev/null || return 1
  done
}
manifests4() { [ "$(nx "$CP" 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]; }
check_eventually 180 "the API answers" api_ok
check_eventually 120 "kube-apiserver mirror pod Ready (the kubelet accepted the manifest)" mirror_ready
check "--profiling=false kept" profiling_off
check "admission plugins valid (NodeRestriction, no PodSecurityPolicy)" plugins_ok
check "serving cert + key flags point at existing files" certs_exist
check "only the 4 control-plane manifests in /etc/kubernetes/manifests" manifests4
verdict
