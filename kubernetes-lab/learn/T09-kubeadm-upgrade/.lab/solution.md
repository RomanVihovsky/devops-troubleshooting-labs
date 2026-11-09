# T09 - solution and takeaways

```
# every node: only the lab repo, then the pinned version
apt-get update -o Dir::Etc::SourceList=sources.list.d/k8slab.list -o Dir::Etc::SourceParts=/dev/null
# k8s-cp1
apt-mark unhold kubeadm && apt-get install -y kubeadm=1.37.1-* && apt-mark hold kubeadm
kubeadm upgrade plan && kubeadm upgrade apply -y v1.37.1
kubectl drain k8s-cp1 --ignore-daemonsets --delete-emptydir-data         # from the desktop
apt-mark unhold kubelet kubectl && apt-get install -y kubelet=1.37.1-* kubectl=1.37.1-* && apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon k8s-cp1
# each worker: kubeadm package, kubeadm upgrade node, drain, kubelet + kubectl, restart, uncordon
```
`./lab` does exactly this in `lib/upgrade.sh` (`cluster_upgrade`), and the baseline build ran it.

**Takeaways**
- Order: control plane (kubeadm → `upgrade apply` → kubelet) → workers (kubeadm → `upgrade node` →
  kubelet). One minor version at a time; you can't skip 1.36 → 1.38.
- Skew policy: kubelet may be up to 3 minors older than the API server, never newer; kubectl ±1.
- `upgrade apply` also renews the control-plane certificates (a yearly upgrade keeps the 1-year certs alive)
  and upgrades CoreDNS and kube-proxy - addons such as the CNI are yours to upgrade.
- Drain respects PodDisruptionBudgets: a PDB with `maxUnavailable: 0` blocks the drain (O/W domains).
  Pods with local storage (local-path) can't move - plan for them.
