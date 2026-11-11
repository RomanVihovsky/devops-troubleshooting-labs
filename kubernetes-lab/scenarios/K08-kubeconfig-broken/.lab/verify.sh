K="$WS/K08/kubeconfig"
k8() { KUBECONFIG=$K KX_TIMEOUT='' kubectl --request-timeout=10s "$@"; }
who() { [ "$(k8 auth whoami -o jsonpath='{.status.userInfo.username}' 2>/dev/null)" = dana ]; }
lists_shop() { k8 get pods -o jsonpath='{.items[*].metadata.namespace}' 2>/dev/null | tr ' ' '\n' | sort -u | grep -qx shop \
               && [ "$(k8 config view --minify -o jsonpath='{..namespace}')" = shop ]; }
endpoint() { [ "$(k8 config view --minify -o jsonpath='{.clusters[0].cluster.server}')" = https://192.168.56.20:6443 ]; }
verified() { [ -z "$(k8 config view --minify -o jsonpath='{.clusters[0].cluster.insecure-skip-tls-verify}')" ] \
             && [ -n "$(k8 config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')" ]; }
check "kubectl auth whoami: dana" who
check "kubectl get pods lists shop (the context's namespace)" lists_shop
check "the server is https://192.168.56.20:6443" endpoint
check "TLS verified with the cluster CA (no insecure-skip-tls-verify)" verified
verdict
