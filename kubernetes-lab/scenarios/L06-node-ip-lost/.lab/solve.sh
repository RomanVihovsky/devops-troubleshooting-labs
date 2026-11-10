nx k8s-w2 "sed -i 's/^KUBELET_KUBEADM_ARGS=\"/KUBELET_KUBEADM_ARGS=\"--node-ip=192.168.56.32 /' /var/lib/kubelet/kubeadm-flags.env && systemctl restart kubelet" </dev/null
ip() { [ "$(kx get node k8s-w2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')" = 192.168.56.32 ]; }
retry 120 ip || true
