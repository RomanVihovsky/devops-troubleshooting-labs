# Desktops get x509 errors from the API, the nodes don't care
**INC-2401** · P2 · Reporter: dev team

Since this morning every `kubectl` from a desktop fails: *tls: failed to verify certificate: x509: certificate
is valid for ..., not 192.168.56.20*. The nodes are fine. Yesterday an engineer "tidied up" the cluster
configuration (`kube-system/kubeadm-config`) and re-issued the API server certificate from it
(`kubeadm init phase certs apiserver`). Make the endpoint valid again - in the certificate **and** in the
cluster's kubeadm configuration, so the next renewal or upgrade doesn't bring the problem back. TLS
verification stays on.

**Test**: `kubectl` from the desktop works through `https://192.168.56.20:6443`; `k8s-cp1`'s API server
certificate has `DNS:k8s-api.lab` and `IP:192.168.56.20` among its SANs; `kubeadm-config` lists both in
`apiServer.certSANs`; all nodes Ready.
