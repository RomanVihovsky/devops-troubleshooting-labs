# K12: kube-controller-manager without --cluster-signing-*: the csrsigning controller doesn't run
nxi "$CP" >/dev/null <<'__X__'
set -eu
f=/etc/kubernetes/manifests/kube-controller-manager.yaml
grep -q -- '--cluster-signing-cert-file' "$f"
grep -v -- '--cluster-signing-\(cert\|key\)-file' "$f" > /var/tmp/kcm.yaml
mv /var/tmp/kcm.yaml "$f"
__X__
kcm_new() { local o; o=$(kx -n kube-system get pod kube-controller-manager-k8s-cp1 -o jsonpath='{.spec.containers[0].command}' 2>/dev/null) || true; [ -n "$o" ] && ! grep -q cluster-signing-cert <<<"$o"; }
retry 180 kcm_new || die "the controller-manager did not restart without the flags"
kcm_ready() { [ "$(kx -n kube-system get pod kube-controller-manager-k8s-cp1 -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)" = true ]; }
retry 180 kcm_ready || die "the controller-manager is not Ready"
t=$(mktemp -d)
openssl req -new -newkey rsa:2048 -nodes -keyout "$t/key" -subj "/CN=ana/O=devs" -out "$t/csr" 2>/dev/null
ka -f - <<YML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: lab-onboard-ana}
spec:
  request: $(base64 -w0 "$t/csr")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 2592000
  usages: [client auth]
YML
rm -rf "$t"
kx certificate approve lab-onboard-ana >/dev/null
sleep 20
! csr_issued lab-onboard-ana || die "the CSR was signed"
