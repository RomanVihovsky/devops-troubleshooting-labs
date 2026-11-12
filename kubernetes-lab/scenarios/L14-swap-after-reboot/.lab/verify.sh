w2_ready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
kubelet_on() { [ "$(nx k8s-w2 'systemctl is-active kubelet' </dev/null)" = active ]; }
no_swap() { [ -z "$(nx k8s-w2 'swapon --show --noheadings' </dev/null)" ]; }
fstab_clean() { ! nx k8s-w2 "awk '\$1 !~ /^#/ && \$3 == \"swap\"' /etc/fstab | grep -q ." </dev/null; }
check_eventually 120 "k8s-w2 Ready" w2_ready
check "kubelet active on k8s-w2" kubelet_on
check "no swap active" no_swap
check "no swap entry in /etc/fstab (next boot is fine)" fstab_clean
verdict
