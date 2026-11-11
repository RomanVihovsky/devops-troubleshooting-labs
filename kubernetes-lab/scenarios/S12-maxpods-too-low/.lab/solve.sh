for w in k8s-w1 k8s-w2 k8s-w3; do
  nx "$w" "sed -i '/^maxPods:/d' /var/lib/kubelet/config.yaml && systemctl restart kubelet" </dev/null
done
retry 180 nodes_ready || true
