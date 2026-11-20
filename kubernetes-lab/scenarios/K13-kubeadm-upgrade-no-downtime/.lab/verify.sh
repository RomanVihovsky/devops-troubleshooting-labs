T=v$(recall k13_target)
api_v() { [ "$(kx version -o json 2>/dev/null | jq -r .serverVersion.gitVersion)" = "$T" ]; }
kubelets_v() { ! kx get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.kubeletVersion}{"\n"}{end}' | grep -vxq "$T"; }
kubeadm_cfg() { kx -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' | grep -qx "kubernetesVersion: $T"; }
none_cordoned() { [ -z "$(kx get nodes -o jsonpath='{range .items[?(@.spec.unschedulable==true)]}{.metadata.name}{end}')" ]; }
pdb_ok() {
  kx -n storefront get pdb -o json | jq -e '[.items[] | select(.spec.selector.matchLabels.app == "storefront")
    | select((.spec.minAvailable // 0) >= 2 or ((.spec.maxUnavailable // 99) | tostring | test("^1$")))] | length > 0' >/dev/null
}
gaps=$(outage_probe gaps k13)
no_outage() { [ "${gaps:-99}" -le 2 ]; }
check "the API server runs $T" api_v
check "every kubelet runs $T" kubelets_v
check "kubeadm-config says $T" kubeadm_cfg
check "no node is cordoned" none_cordoned
check_eventually 120 "storefront: 3 Ready replicas" deploy_ready storefront storefront 3
check "a PodDisruptionBudget keeps at least 2 storefront pods up" pdb_ok
check "the prober on gw saw at most 2 failed probes ($gaps)" no_outage
verdict
