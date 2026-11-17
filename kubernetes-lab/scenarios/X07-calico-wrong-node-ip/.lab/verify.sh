calico_ready() { [ "$(kx -n kube-system get ds calico-node -o jsonpath='{.status.numberReady}/{.status.desiredNumberScheduled}' 2>/dev/null)" = 4/4 ]; }
addrs_ok() {
  kx get nodes -o json | jq -e '[.items[].metadata.annotations["projectcalico.org/IPv4Address"] // "" | startswith("192.168.56.")] | all' >/dev/null
}
mesh() { ns_matrix meshcheck app=echo; }
rolling() { [ "$(kx -n kube-system get ds calico-node -o jsonpath='{.spec.updateStrategy.type}' 2>/dev/null)" = RollingUpdate ]; }
check_eventually 180 "calico-node is Ready on all 4 nodes" calico_ready
check_eventually 60 "every node's Calico address is on 192.168.56.0/24" addrs_ok
check_eventually 90 "every meshcheck pod reaches every other one across nodes" mesh
check "calico-node rolls updates out to all nodes (RollingUpdate)" rolling
verdict
