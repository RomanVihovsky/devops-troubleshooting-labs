## Hint 1
`kubectl get csr` - Approved, but no `Issued`. Who issues certificates for `kubernetes.io/kube-apiserver-client`
CSRs? Look at the controller-manager's logs: `kubectl -n kube-system logs kube-controller-manager-k8s-cp1 | grep -i csr`.

## Hint 2
The **csrsigning** controller in kube-controller-manager signs approved CSRs - with the CA files given by
`--cluster-signing-cert-file` / `--cluster-signing-key-file`. Without them it doesn't start at all. They are not
"defaults" in a kubeadm cluster.

## Hint 3
Put `--cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt` and `--cluster-signing-key-file=/etc/kubernetes/pki/ca.key`
back into `/etc/kubernetes/manifests/kube-controller-manager.yaml`. Approved CSRs are signed once the controller runs.
