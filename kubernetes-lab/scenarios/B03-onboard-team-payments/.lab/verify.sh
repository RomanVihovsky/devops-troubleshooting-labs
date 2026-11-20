tina() { KUBECONFIG="$STATE_DIR/scenario.b03-tina.kubeconfig" kubectl "$@"; }
rbac_ok() {
  [ "$(tina -n payments-team auth can-i create deployments 2>/dev/null)" = yes ] && [ "$(tina -n default auth can-i create deployments 2>/dev/null)" = no ]
}
baseline() {
  [ "$(kx -n payments-team get resourcequota team-quota -o jsonpath='{.spec}' 2>/dev/null)" = "$(recall b03_quota)" ] \
    && [ "$(kx -n payments-team get networkpolicy default-deny -o jsonpath='{.spec}' 2>/dev/null)" = "$(recall b03_deny)" ] \
    && [ "$(kx get ns payments-team -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}')" = restricted ]
}
check "tina can create Deployments in payments-team, not in default" rbac_ok
check_eventually 150 "ledger: 1 Ready pod" deploy_ready payments-team ledger 1
check_eventually 150 "payments-api: 2 Ready pods (reaches ledger)" deploy_ready payments-team payments-api 2
check "quota, Pod Security restricted and default-deny unchanged" baseline
verdict
