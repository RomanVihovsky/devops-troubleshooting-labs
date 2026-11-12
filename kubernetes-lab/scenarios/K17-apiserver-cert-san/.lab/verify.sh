api_up() { [ "$(kx get --raw /readyz 2>/dev/null)" = ok ]; }
sans() { nx "$CP" 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -ext subjectAltName' </dev/null; }
cert_ok() { sans | grep -q 'DNS:k8s-api.lab' && sans | grep -qE 'IP Address:192\.168\.56\.20(,|$)'; }
cfg_ok() {
  nx "$CP" "kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}'" </dev/null \
    | python3 -c 'import sys, yaml
s = [str(x) for x in ((yaml.safe_load(sys.stdin) or {}).get("apiServer") or {}).get("certSANs") or []]
sys.exit(0 if "k8s-api.lab" in s and "192.168.56.20" in s else 1)'
}
check_eventually 120 "kubectl from the desktop via https://192.168.56.20:6443 (TLS verified)" api_up
check "the API server cert has DNS:k8s-api.lab and IP:192.168.56.20" cert_ok
check "kubeadm-config apiServer.certSANs lists k8s-api.lab and 192.168.56.20" cfg_ok
check_eventually 120 "all nodes Ready" nodes_ready
verdict
