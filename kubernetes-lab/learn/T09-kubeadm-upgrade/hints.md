## Hint 1
On a node: `apt-get update -o Dir::Etc::SourceList=sources.list.d/k8slab.list -o Dir::Etc::SourceParts=/dev/null`
(only the lab repo - works offline), `apt-cache madison kubeadm`, then
`apt-mark unhold kubeadm && apt-get install -y kubeadm=1.37.1-* && apt-mark hold kubeadm`.

## Hint 2
`kubeadm upgrade apply v1.37.1` rewrites the static pod manifests one by one (etcd, apiserver,
controller-manager, scheduler), renews the certificates and updates kubeadm-config, CoreDNS and kube-proxy.
The kubelets are **not** touched: that's your step 2/3. Drain from the desktop:
`kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`.

## Hint 3
Workers run `kubeadm upgrade node` (not `apply`): it only updates the local kubelet config. After the
kubelet restart on k8s-cp1 the static pods restart too - the API may be gone or answer `Forbidden` for a
minute; retry the uncordon. Version skew rule: kubelet ≤ API server, never newer - that's why the control
plane goes first.
