# K08: dana's kubeconfig (a real client cert via the CSR API) with three edits: port, context user, namespace
kx create clusterrolebinding k08-dana-view --clusterrole=view --user=dana --dry-run=client -o yaml | ka -f -
user_kubeconfig dana k08-sre kubeconfig || die "could not issue dana's certificate"
export KUBECONFIG=$PWD/kubeconfig
kubectl config set-cluster lab --server=https://192.168.56.20:6444 >/dev/null
kubectl config rename-context dana@lab lab >/dev/null
kubectl config set-context lab --user=dana@lab --namespace=shp >/dev/null
kubectl config use-context lab >/dev/null
! kubectl get pods >/dev/null 2>&1 || die "the kubeconfig still works"
