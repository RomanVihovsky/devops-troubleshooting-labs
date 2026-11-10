w3_ready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
cni_conf() { nx k8s-w3 'ls /etc/cni/net.d/*.conflist >/dev/null 2>&1' </dev/null; }
pod_net() {   # a pod pinned to k8s-w3 resolves and reaches the API Service
  local p="l04-probe-$RANDOM" ph=""
  kx run "$p" --image="$BUSYBOX_IMAGE" --restart=Never --labels="$LAB_LABEL=$LAB_ID" --overrides='{"spec":{"nodeName":"k8s-w3"}}' \
    --command -- nslookup -timeout=3 kubernetes.default.svc.cluster.local >/dev/null 2>&1 || return 1
  for _ in $(seq 40); do ph=$(kx get pod "$p" -o jsonpath='{.status.phase}' 2>/dev/null); case $ph in Succeeded|Failed) break ;; esac; sleep 2; done
  kx delete pod "$p" --wait=false >/dev/null 2>&1; [ "$ph" = Succeeded ]
}
check_eventually 120 "k8s-w3 Ready" w3_ready
check "k8s-w3 has a CNI config (/etc/cni/net.d/*.conflist)" cni_conf
check_eventually 60 "a new pod on k8s-w3 gets networking (DNS + Service)" pod_net
verdict
