openssl req -new -key alice.key -subj "/CN=alice/O=dev-team" -out alice.csr
kx apply -f - >/dev/null <<YML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: alice}
spec:
  request: $(base64 -w0 alice.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 7776000
  usages: [client auth]
YML
kx certificate approve alice >/dev/null
issued() { [ -n "$(kx get csr alice -o jsonpath='{.status.certificate}')" ]; }
retry 30 issued || die "no certificate"
kx get csr alice -o jsonpath='{.status.certificate}' | base64 -d > alice.crt
KUBECONFIG=$PWD/kubeconfig kubectl config set-credentials alice --client-certificate=alice.crt --client-key=alice.key --embed-certs >/dev/null
