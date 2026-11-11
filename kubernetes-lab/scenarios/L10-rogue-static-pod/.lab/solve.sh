nx k8s-w2 'rm -f /etc/kubernetes/manifests/netdebug.yaml' </dev/null
gone() { ! kx -n default get pod netdebug-k8s-w2 >/dev/null 2>&1; }
retry 60 gone || true
