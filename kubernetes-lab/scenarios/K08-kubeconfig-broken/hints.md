## Hint 1
`export KUBECONFIG=$PWD/workspace/K08/kubeconfig` (in your shell, from the lab directory), then
`kubectl config view` and `kubectl config get-contexts`. Read each error message: it names the layer.

## Hint 2
There are three mistakes, one per layer: the cluster's `server`, the context's `user` (it must name an entry
under `users:`), and the context's `namespace`.

## Hint 3
`kubectl config set-cluster lab --server=https://192.168.56.20:6443`;
`kubectl config set-context --current --user=dana --namespace=shop`.
