# L06 - the node registered its NAT address

**Root cause**: without `--node-ip`, the kubelet looks its hostname up first. On k8s-w2 `/etc/hosts` has
cloud-init's `127.0.1.1 k8s-w2`; a loopback address is not a valid node IP, so the kubelet falls back to the
address of its default route - `10.0.2.15` on the VirtualBox NAT NIC, which every VM has. The API server connects to
`<InternalIP>:10250` for logs, exec, port-forward and metrics: 10.0.2.15 is its *own* NAT address, the
connection goes nowhere. Pod traffic (Calico pins its addresses separately) keeps working.

**Diagnosis**: `kubectl get nodes -o wide` (INTERNAL-IP 10.0.2.15), `kubectl logs` timeout, on the node
`cat /var/lib/kubelet/kubeadm-flags.env` and `getent hosts k8s-w2`.

**Fix**: `--node-ip=192.168.56.32` back into the kubelet flags, restart. Fixing only `/etc/hosts` also
passes the test, but it leaves the node IP to name resolution: the next cloud-init run or hosts rewrite breaks
it again. The explicit flag is the durable fix.

**Interview notes**
- Multi-NIC nodes (VirtualBox, bare metal with storage/management networks, some clouds) need an explicit
  node IP; kubeadm puts `kubeletExtraArgs` into `kubeadm-flags.env`.
- The kubelet's order without `--node-ip`: an IP given as `--hostname-override` → the hostname's DNS/hosts
  answer (no loopback/link-local) → the default-route interface.
- logs/exec/port-forward = API server → kubelet:10250; kubectl → node directly is never involved. A firewall
  on 10250 or a wrong InternalIP breaks exactly these.
- The same class: wrong `advertiseAddress` on the control plane, Calico's autodetection picking the wrong
  NIC (here pinned with `cidr=`).
