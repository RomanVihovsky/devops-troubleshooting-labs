[ -n "${LAB_EXPECT_FAIL:-}" ] && w=10 || w=60
fresh_signed() {
  local n="lab-k12-$RANDOM" t r=1; t=$(mktemp -d)
  openssl req -new -newkey rsa:2048 -nodes -keyout "$t/key" -subj "/CN=k12-probe" -out "$t/csr" 2>/dev/null
  kx apply -f - >/dev/null 2>&1 <<YML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: $n, labels: {$LAB_LABEL: $LAB_ID}}
spec:
  request: $(base64 -w0 "$t/csr")
  signerName: kubernetes.io/kube-apiserver-client
  usages: [client auth]
YML
  kx certificate approve "$n" >/dev/null 2>&1
  if retry "$w" csr_issued "$n"; then
    kx get csr "$n" -o jsonpath='{.status.certificate}' | base64 -d > "$t/crt"
    nx "$CP" 'cat /etc/kubernetes/pki/ca.crt' </dev/null > "$t/ca" 2>/dev/null
    openssl verify -CAfile "$t/ca" "$t/crt" >/dev/null 2>&1 && r=0
  fi
  kx delete csr "$n" --ignore-not-found >/dev/null 2>&1; rm -rf "$t"
  return $r
}
check "a new approved client CSR is signed by the cluster CA" fresh_signed
check_eventually 60 "lab-onboard-ana has its certificate" csr_issued lab-onboard-ana
check_eventually 120 "all nodes Ready" nodes_ready
check "the API answers" kx get --raw /readyz
verdict
