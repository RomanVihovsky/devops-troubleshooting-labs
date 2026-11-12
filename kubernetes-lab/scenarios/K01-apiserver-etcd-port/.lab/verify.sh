api_up() { [ "$(kx get --raw /readyz 2>/dev/null)" = ok ]; }
flag_fixed() { nx k8s-cp1 "grep -q -- '--etcd-servers=https://127.0.0.1:2379\$' /etc/kubernetes/manifests/kube-apiserver.yaml" </dev/null; }
no_stray_manifests() {   # an edited copy left in manifests/ would run a second apiserver
  [ "$(nx k8s-cp1 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]
}
apiserver_ready() {
  [ "$(kx -n kube-system get pod -l component=kube-apiserver -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]
}
writes_work() {
  local n="k01-probe-$RANDOM"
  kx -n default create configmap "$n" --from-literal=ok=1 >/dev/null 2>&1 && kx -n default delete configmap "$n" >/dev/null 2>&1
}
check_eventually 120 "the API answers through k8s-api.lab (haproxy on k8s-gw)" api_up
check "--etcd-servers points at etcd's client port 2379 in the static pod manifest" flag_fixed
check "only the 4 control-plane manifests in /etc/kubernetes/manifests" no_stray_manifests
check_eventually 60 "the kube-apiserver pod is Ready" apiserver_ready
check "the API accepts writes (ConfigMap create + delete)" writes_work
verdict
