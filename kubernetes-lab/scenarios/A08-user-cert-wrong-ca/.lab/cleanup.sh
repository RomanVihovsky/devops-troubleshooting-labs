# user CSRs (signer kube-apiserver-client) the student made for alice
for c in $(kx get csr -o json | jq -r '.items[] | select(.spec.signerName == "kubernetes.io/kube-apiserver-client" and true) | .metadata.name'); do
  kx delete csr "$c" >/dev/null 2>&1
done
kx delete csr alice --ignore-not-found >/dev/null 2>&1
true
