resolves() {
  local p="dns-probe-$RANDOM" out
  out=$(kx run "$p" -n default --rm -i --restart=Never --quiet --image="$BUSYBOX_IMAGE" --labels="$LAB_LABEL=$LAB_ID" --command -- \
        sh -c "nslookup -timeout=3 $1 >/dev/null 2>&1 && echo ok" 2>/dev/null)
  [ "$(echo "$out" | tail -1)" = ok ]
}
dns_ready() { kx -n kube-system rollout status deploy/coredns --timeout=5s >/dev/null 2>&1; }
check_eventually 90 "a pod resolves an external name (pkgs.k8s.io)" resolves pkgs.k8s.io
check "a pod resolves kubernetes.default.svc.cluster.local" resolves kubernetes.default.svc.cluster.local
check "CoreDNS Ready" dns_ready
verdict
