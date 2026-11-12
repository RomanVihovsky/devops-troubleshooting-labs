cluster_join k8s-w3     # token + CA hash from cp1, JoinConfiguration with node-ip (infra/node/kubeadm-join.yaml.tpl)
w3_ready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 180 w3_ready || die "k8s-w3 not Ready"
approve_pending_csrs
kx label node k8s-w3 topology.kubernetes.io/zone=zone-b --overwrite >/dev/null
