# K01: kube-apiserver points at etcd on the wrong port -> the API never becomes healthy
nx k8s-cp1 "sed -i 's|--etcd-servers=https://127.0.0.1:2379|--etcd-servers=https://127.0.0.1:2397|' /etc/kubernetes/manifests/kube-apiserver.yaml" </dev/null
api_down() { ! KX_TIMEOUT=5s kx get --raw /readyz >/dev/null 2>&1; }
retry 180 api_down || die "the API server did not go down"
