# L06: --node-ip removed from the kubelet flags on k8s-w2 - it registers 10.0.2.15 (NAT, the same on every VM).
# Without --node-ip the kubelet first resolves its hostname and only falls back to the default-route NIC when
# that gives nothing usable: so k8s-w2 also gets Ubuntu's cloud-init hosts entry 127.0.1.1 (loopback = skipped).
# Only the k8s-w2 line changes (registry.lab etc. must keep resolving); /etc/hosts is in the node golden.
# The flag may be the only one: KUBELET_KUBEADM_ARGS="--node-ip=192.168.56.32"
nx k8s-w2 "sed -i -E 's/([\" ])--node-ip=[0-9.]+ ?/\1/' /var/lib/kubelet/kubeadm-flags.env && ! grep -q node-ip /var/lib/kubelet/kubeadm-flags.env \
  && sed -i -E 's/^192\.168\.56\.32[[:space:]]+k8s-w2\b.*/127.0.1.1 k8s-w2/' /etc/hosts && grep -q '^127.0.1.1 k8s-w2' /etc/hosts \
  && systemctl restart kubelet" </dev/null
natip() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')" = 10.0.2.15 ]; }
retry 120 natip || die "k8s-w2 kept its host-only IP"
