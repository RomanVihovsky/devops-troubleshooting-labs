w2_ready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ]; }
kubelet_enabled() { [ "$(nx k8s-w2 'systemctl is-enabled kubelet' </dev/null)" = enabled ]; }
kubelet_active() { [ "$(nx k8s-w2 'systemctl is-active kubelet' </dev/null)" = active ]; }
runs_pods() {   # a throwaway pod pinned to k8s-w2 must run to completion
  local p="l01-probe-$RANDOM" phase
  kx run "$p" --image="$BUSYBOX_IMAGE" --restart=Never --labels="$LAB_LABEL=$LAB_ID" \
    --overrides='{"spec":{"nodeName":"k8s-w2"}}' --command -- true >/dev/null 2>&1 || return 1
  for _ in $(seq 30); do
    phase=$(kx get pod "$p" -o jsonpath='{.status.phase}' 2>/dev/null)
    [ "$phase" = Succeeded ] && break; sleep 2
  done
  kx delete pod "$p" --wait=false >/dev/null 2>&1
  [ "$phase" = Succeeded ]
}
check_eventually 120 "k8s-w2 is Ready" w2_ready
check "kubelet is active on k8s-w2" kubelet_active
check "kubelet is enabled (comes back after a reboot)" kubelet_enabled
check_eventually 60 "k8s-w2 runs pods again" runs_pods
verdict
