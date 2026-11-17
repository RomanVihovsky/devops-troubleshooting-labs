long() {
  nx "$CP" 'set -e
for f in /etc/kubernetes/pki/{apiserver,apiserver-kubelet-client,apiserver-etcd-client,front-proxy-client}.crt \
         /etc/kubernetes/pki/etcd/{server,peer,healthcheck-client}.crt; do
  openssl x509 -checkend 25920000 -noout -in "$f" >/dev/null
done
for k in admin controller-manager scheduler super-admin; do
  [ -f /etc/kubernetes/$k.conf ] || continue
  grep client-certificate-data /etc/kubernetes/$k.conf | awk "{print \$2}" | base64 -d | openssl x509 -checkend 25920000 -noout >/dev/null
done' </dev/null >/dev/null 2>&1
}
config_ok() {
  kx -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' 2>/dev/null | python3 -c 'import re, sys, yaml
v = (yaml.safe_load(sys.stdin) or {}).get("certificateValidityPeriod")
if v is None: sys.exit(0)
h = sum(float(n) * {"h": 1, "m": 1/60, "s": 1/3600}[u] for n, u in re.findall(r"([0-9.]+)([hms])", str(v)))
sys.exit(0 if h >= 8760 else 1)'
}
api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
check_eventually 180 "the API answers" api_ok
check "every control-plane certificate and kubeconfig on cp1 is valid for > 300 days" long
check "kubeadm-config has no short certificateValidityPeriod" config_ok
check_eventually 180 "all nodes Ready" nodes_ready
verdict
