K="$WS/A08/kubeconfig"
ak() { KUBECONFIG=$K kubectl --request-timeout=10s "$@"; }
who() { [ "$(ak auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null)" = alice ]; }
cert() { ak config view --raw --minify -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d; }
signed_by_cluster() {
  local d; d=$(mktemp -d)
  kx config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$d/ca"
  cert > "$d/crt"; openssl verify -CAfile "$d/ca" "$d/crt" >/dev/null 2>&1; local rc=$?; rm -rf "$d"; return $rc
}
same_key() { [ "$(cert | openssl x509 -noout -pubkey 2>/dev/null | sha256sum | cut -d' ' -f1)" = "$(recall a08_key)" ]; }
not_more() { ! ak -n kube-system get pods >/dev/null 2>&1; }
check "kubectl auth whoami: alice" who
check "alice can list pods in dev" ak -n dev get pods
check "her certificate is signed by the cluster CA" signed_by_cluster
check "...and matches her original key" same_key
check "she can't list pods in kube-system" not_more
verdict
