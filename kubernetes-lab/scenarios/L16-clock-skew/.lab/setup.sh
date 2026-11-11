# L16: chrony stopped + disabled on w1, the clock 400 days back: the kubelet's client cert is "not yet valid"
remember l16_cert "$(nx k8s-w1 'openssl x509 -noout -fingerprint -sha256 -in /var/lib/kubelet/pki/kubelet-client-current.pem' </dev/null)"
# (the kubelet restart matters: certificates are checked at the TLS handshake - an open connection keeps working)
nx k8s-w1 'systemctl disable --now chrony >/dev/null 2>&1; date -s "-400 days" >/dev/null; systemctl restart kubelet' </dev/null
notready() { [ "$(kx get node k8s-w1 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ]; }
retry 180 notready || die "k8s-w1 stayed Ready"
