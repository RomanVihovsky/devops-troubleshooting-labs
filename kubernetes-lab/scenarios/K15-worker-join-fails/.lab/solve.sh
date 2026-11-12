cluster_join k8s-w3     # a fresh token (30 min) + the CA hash, JoinConfiguration with node-ip
w3_ready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 180 w3_ready || die "k8s-w3 not Ready"
approve_pending_csrs
kx label node k8s-w3 topology.kubernetes.io/zone=zone-b --overwrite >/dev/null
