export KUBECONFIG=$PWD/kubeconfig
kubectl config set-cluster lab --server=https://192.168.56.20:6443 >/dev/null
kubectl config set-context --current --user=dana --namespace=shop >/dev/null
