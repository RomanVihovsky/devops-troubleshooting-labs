w3_ready() { [ "$(kx get node k8s-w3 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
loaded() { nx k8s-w3 'lsmod | grep -q "^br_netfilter "' </dev/null; }
sysctls() { [ "$(nx k8s-w3 'sysctl -n net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward 2>/dev/null | tr "\n" " "' </dev/null)" = "1 1 1 " ]; }
# the fix must survive a reboot - the test reboots w3 (not in selftest's broken pass)
[ -n "${LAB_EXPECT_FAIL:-}" ] || check "k8s-w3 rebooted (the test's reboot)" node_reboot k8s-w3
check_eventually 240 "k8s-w3 Ready" w3_ready
check "br_netfilter loaded after boot" loaded
check "bridge-nf-call-iptables/-ip6tables and ip_forward = 1" sysctls
verdict
