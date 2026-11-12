tok() { tr -d '\n' < "$WS/A11/ci-token.txt" 2>/dev/null; }
ca=$(mktemp); kx config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$ca"
srv=$(kx config view --minify -o jsonpath='{.clusters[0].cluster.server}')
tk() { kubectl --kubeconfig=/dev/null --server="$srv" --certificate-authority="$ca" --token="$(tok)" --request-timeout=10s "$@"; }
who() { [ "$(tk auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null)" = system:serviceaccount:ci2:ci-bot ]; }
from_secret() { kx -n ci2 get secrets -o json | jq -e --arg t "$(tok)" '[.items[] | select(.type == "kubernetes.io/service-account-token"
  and .metadata.annotations["kubernetes.io/service-account.name"] == "ci-bot" and (.data.token | @base64d) == $t)] | length == 1' >/dev/null; }
check "the token authenticates as ci2/ci-bot" who
check "it can list pods in ci2" tk -n ci2 get pods
check "it comes from a service-account-token Secret for ci-bot" from_secret
rm -f "$ca"
verdict
