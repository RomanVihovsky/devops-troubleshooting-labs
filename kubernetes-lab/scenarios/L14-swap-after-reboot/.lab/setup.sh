# L14: a swap file in fstab, then a reboot: the kubelet refuses to start
nx k8s-w2 'fallocate -l 512M /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && echo "/swapfile none swap sw 0 0" >> /etc/fstab' </dev/null
nx k8s-w2 'systemctl reboot' </dev/null >/dev/null 2>&1 || true
sleep 20
back() { nx k8s-w2 'swapon --show | grep -q swapfile' </dev/null; }
retry 300 back || die "k8s-w2 did not come back with swap on"
notready() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 120 notready || die "k8s-w2 is Ready with swap"
