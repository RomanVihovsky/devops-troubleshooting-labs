# T02 · kubeadm anatomy: static pods, PKI, kubelet config, kubeadm-config
**Learn** · what kubeadm left on the nodes, and where every incident in the K and L domains hides · ~30 min

Nothing is broken. Read the cluster's anatomy on the nodes (`./lab node cp1`, `./lab node w1`, then
`sudo -i`) and record what you find in `workspace/T02/answers.yaml`.

1. **kubelet** (on k8s-w1): `systemctl cat kubelet` shows the unit and its drop-in. Which files does it
   read? `/var/lib/kubelet/config.yaml` is the KubeletConfiguration: note the **cgroup driver** and the
   **staticPodPath**. The flags kubeadm added at join time (the node IP!) are in another file - **which one**?
2. **kubeconfigs**: `/etc/kubernetes/kubelet.conf` on a worker - **which server URL** does the kubelet use?
   On k8s-cp1, `/etc/kubernetes/admin.conf` holds a client certificate: decode it
   (`grep client-certificate-data ... | awk '{print $2}' | base64 -d | openssl x509 -noout -subject`).
   **Which group (O=)** makes it cluster-admin?
3. **Static pods** (on k8s-cp1): the 4 manifests in the staticPodPath. In `etcd.yaml`: the **data dir**.
4. **PKI**: `kubeadm certs check-expiration` and `/etc/kubernetes/pki`. In **which year** does the cluster CA
   expire?
5. **kubeadm-config**: `kubectl -n kube-system get cm kubeadm-config -o yaml` - the **service CIDR**.

**Test**: the 8 answers match the live cluster.
