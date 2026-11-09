# T09 · kubeadm upgrade: 1.36 → 1.37, control plane first, then node by node
**Learn** · the official procedure, by hand, on a real cluster · ~45 min (setup builds the old cluster: ~5 min)

Setup rebuilt the cluster **bare at v1.36** (control plane + 3 workers + Calico; the addons and the GitOps
stack come back with the next lab's reset). Upgrade it to **v1.37.1** the way the Kubernetes docs describe
("Upgrading kubeadm clusters"). The packages come from k8s-gw's apt repo
(`/etc/apt/sources.list.d/k8slab.list`, both minors are there; `apt-cache madison kubeadm`).

1. **k8s-cp1**: upgrade the **kubeadm** package first (it is held: `apt-mark unhold` / `hold`),
   `kubeadm upgrade plan`, then `kubeadm upgrade apply v1.37.1`.
2. **k8s-cp1's kubelet**: `kubectl drain` it, upgrade **kubelet + kubectl**, `systemctl daemon-reload &&
   systemctl restart kubelet`, `kubectl uncordon`.
3. **Each worker**, one at a time: kubeadm package → `kubeadm upgrade node` → drain → kubelet + kubectl →
   restart kubelet → uncordon.
4. `kubectl get nodes` - every node v1.37.1, nothing SchedulingDisabled.

**Test**: the API server and every kubelet run v1.37.1, kubeadm-config says v1.37.1, the kubeadm package is
1.37.1 on every node, no node is cordoned, all are Ready, and a new pod runs.
