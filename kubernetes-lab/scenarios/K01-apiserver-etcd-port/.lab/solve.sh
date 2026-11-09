nx k8s-cp1 "sed -i 's|--etcd-servers=https://127.0.0.1:2397|--etcd-servers=https://127.0.0.1:2379|' /etc/kubernetes/manifests/kube-apiserver.yaml" </dev/null
retry 180 kx get --raw /readyz || true
