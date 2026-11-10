active() { [ "$(nx k8s-w1 'systemctl is-active containerd; systemctl is-enabled containerd' </dev/null | tr '\n' ' ')" = "active enabled " ]; }
parses() { nx k8s-w1 'containerd config dump >/dev/null 2>&1' </dev/null; }
tuned() { nx k8s-w1 "containerd config dump 2>/dev/null | grep -Eq '^\s*max_concurrent_downloads = 10\$'" </dev/null; }
w1_ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
runs_pods() {
  local p="l02-probe-$RANDOM" ph=""
  kx run "$p" --image="$BUSYBOX_IMAGE" --restart=Never --labels="$LAB_LABEL=$LAB_ID" --overrides='{"spec":{"nodeName":"k8s-w1"}}' --command -- true >/dev/null 2>&1 || return 1
  for _ in $(seq 30); do ph=$(kx get pod "$p" -o jsonpath='{.status.phase}' 2>/dev/null); [ "$ph" = Succeeded ] && break; sleep 2; done
  kx delete pod "$p" --wait=false >/dev/null 2>&1; [ "$ph" = Succeeded ]
}
check "containerd active + enabled on k8s-w1" active
check "containerd's config loads (containerd config dump)" parses
check "max_concurrent_downloads = 10 kept" tuned
check_eventually 120 "k8s-w1 Ready" w1_ready
check_eventually 60 "k8s-w1 runs new pods" runs_pods
verdict
