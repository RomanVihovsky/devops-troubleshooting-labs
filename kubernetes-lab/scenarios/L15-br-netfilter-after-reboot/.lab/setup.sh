# L15: br_netfilter dropped from modules-load.d, then a reboot: the bridge sysctls are gone (silent on Calico)
nx k8s-w3 "sed -i '/^br_netfilter\$/d' /etc/modules-load.d/k8s.conf && ! grep -rqs br_netfilter /etc/modules-load.d" </dev/null
node_reboot k8s-w3 || die "k8s-w3 did not come back"
w3_ready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
retry 240 w3_ready || die "k8s-w3 not Ready after the reboot"
nx k8s-w3 '! lsmod | grep -q "^br_netfilter "' </dev/null || die "br_netfilter got loaded anyway"
