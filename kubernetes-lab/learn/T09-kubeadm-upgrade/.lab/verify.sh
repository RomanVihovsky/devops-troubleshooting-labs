T=v$(recall t09_target)
api_v() { [ "$(kx version -o json 2>/dev/null | jq -r .serverVersion.gitVersion)" = "$T" ]; }
kubelets_v() { ! kx get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.kubeletVersion}{"\n"}{end}' | grep -vxq "$T"; }
kubeadm_cfg() { kx -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' | grep -qx "kubernetesVersion: $T"; }
kubeadm_pkgs() {
  local n
  for n in $(cluster_nodes); do
    nx "$n" "dpkg-query -W -f '\${Version}' kubeadm" </dev/null | grep -q "^${T#v}-" || return 1
  done
}
none_cordoned() { [ -z "$(kx get nodes -o jsonpath='{range .items[?(@.spec.unschedulable==true)]}{.metadata.name}{end}')" ]; }
pod_runs() {
  local p="t09-probe-$RANDOM" ph=""
  kx run "$p" -n default --image="$BUSYBOX_IMAGE" --restart=Never --labels="$LAB_LABEL=$LAB_ID" --command -- true >/dev/null 2>&1 || return 1
  for _ in $(seq 40); do ph=$(kx -n default get pod "$p" -o jsonpath='{.status.phase}' 2>/dev/null); [ "$ph" = Succeeded ] && break; sleep 2; done
  kx -n default delete pod "$p" --wait=false >/dev/null 2>&1
  [ "$ph" = Succeeded ]
}
check "API server runs $T" api_v
check "every kubelet runs $T" kubelets_v
check "kubeadm-config: kubernetesVersion $T" kubeadm_cfg
check "kubeadm package ${T#v} on every node" kubeadm_pkgs
check "no node cordoned" none_cordoned
check_eventually 120 "all nodes Ready" nodes_ready
check_eventually 30 "a new pod runs" pod_runs
verdict
