no_loss() { ! nx k8s-w1 'tc qdisc show' </dev/null 2>/dev/null | grep -q 'netem.*loss'; }
ready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
lease_fresh() {
  local t; t=$(kx -n kube-node-lease get lease k8s-w1 -o jsonpath='{.spec.renewTime}' 2>/dev/null) || return 1
  [ -n "$t" ] && [ $(( $(date +%s) - $(date -d "$t" +%s) )) -lt 30 ]
}
check "no netem loss on w1's interfaces" no_loss
check_eventually 120 "k8s-w1 is Ready" ready
[ -n "${LAB_EXPECT_FAIL:-}" ] && n=6 || n=12
samples=""; ok=1
for _ in $(seq "$n"); do
  if ready && lease_fresh; then samples="${samples}+"; else samples="${samples}-"; ok=0; fi
  sleep 10
done
stable() { [ "$ok" = 1 ]; }
check "Ready with a fresh lease for $((n * 10)) s ($samples)" stable
verdict
