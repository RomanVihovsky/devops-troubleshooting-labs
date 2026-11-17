# K12 - no signing flags, no csrsigning controller

**Root cause**: approving a CSR only sets a condition. **Signing** is done by the csrsigning controller inside
kube-controller-manager, using the CA given by `--cluster-signing-cert-file` / `--cluster-signing-key-file` (kubeadm
sets both to `/etc/kubernetes/pki/ca.*`). The "cleanup" removed them; without them the controller doesn't start
(the log says so at start-up), so approved CSRs wait forever - for people, and for kubelet serving certificates.

**Diagnosis**
```
kubectl get csr                                                     # Approved, no Issued
kubectl -n kube-system logs kube-controller-manager-k8s-cp1 | grep -iE 'csr|signing'
grep -n cluster-signing /etc/kubernetes/manifests/kube-controller-manager.yaml     # on cp1: nothing
```

**Fix**: add both flags back to the static pod manifest; the kubelet restarts the controller-manager and it signs
the approved backlog.

**Interview notes**
- Per-signer flags exist too (`--cluster-signing-kube-apiserver-client-cert-file`, ...-kubelet-serving-..., ...) for
  separate CAs; `--cluster-signing-duration` caps the lifetime (default 1 year; `expirationSeconds` may shorten it).
- Kubelet **client** cert rotation needs the CSR to be auto-approved (csrapproving controller + RBAC for nodes) and
  signed; serving certs (`serverTLSBootstrap`) are never auto-approved.
- "Flags that repeat defaults" - check the component's defaults for **your** installer: kubeadm sets many.
