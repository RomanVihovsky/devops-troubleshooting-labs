dns_ready() { [ "$(kx -n kube-system get deploy coredns -o jsonpath='{.status.readyReplicas}/{.spec.replicas}')" = "$(kx -n kube-system get deploy coredns -o jsonpath='{.spec.replicas}/{.spec.replicas}')" ]; }
resolves() {
  local p="dns-probe-$RANDOM" out
  out=$(kx run "$p" -n default --rm -i --restart=Never --quiet --image="$BUSYBOX_IMAGE" --labels="$LAB_LABEL=$LAB_ID" --command -- \
        sh -c "nslookup -timeout=3 $1 >/dev/null 2>&1 && echo ok" 2>/dev/null)
  [ "$(echo "$out" | tail -1)" = ok ]
}
check_eventually 120 "CoreDNS Ready" dns_ready
check_eventually 60 "a pod resolves kubernetes.default.svc.cluster.local" resolves kubernetes.default.svc.cluster.local
check_eventually 30 "a pod resolves git.lab (lab zone)" resolves git.lab
if [ -f "$STATE_DIR/offline" ]; then echo "  - external name skipped (vm offline)"
else check_eventually 30 "a pod resolves an external name (pkgs.k8s.io)" resolves pkgs.k8s.io; fi
verdict
