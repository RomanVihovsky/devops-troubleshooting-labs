# L04 - CNI config deleted

**Root cause**: `/etc/cni/net.d/` on k8s-w3 is empty. The kubelet asks the runtime for network status,
containerd finds no CNI config: `NetworkReady=false`, node NotReady, no new pod sandboxes.

**Diagnosis**: `kubectl describe node k8s-w3`; on the node `ls /etc/cni/net.d`, `crictl info | grep -A5
NetworkReady`.

**Fix**: restart the calico-node pod on k8s-w3 - its `install-cni` init container rewrites
`10-calico.conflist` and the CNI kubeconfig.

**Interview notes**
- CNI = config in `/etc/cni/net.d` + binaries in `/opt/cni/bin`, called by the runtime for every sandbox.
  Most CNIs install both from a DaemonSet - delete the files and only a pod restart brings them back.
- Existing pods keep working (their interfaces exist); only new sandboxes fail - a "half broken" node.
- The same message appears on a fresh node before the CNI is installed (`kubeadm init` → nodes NotReady
  until you apply the CNI).
