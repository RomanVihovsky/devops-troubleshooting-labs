# K13 - a kubeadm upgrade blocked by a PodDisruptionBudget

**Root cause of the aborted attempt**: storefront's PDB says `minAvailable: 3` with 3 replicas - **0 allowed
disruptions**. `kubectl drain` evicts through the Eviction API, which refuses (429) and the drain retries forever.
Deleting the PDB or `drain --disable-eviction` would "work" - and take storefront below its capacity with no guard.

**Fix**: make the budget possible - `minAvailable: 2` (or `maxUnavailable: 1`) - then upgrade node by node:
```
# k8s-cp1
apt-get install -y kubeadm=1.37.*            # (the lab's apt repo has it)
kubeadm upgrade plan && kubeadm upgrade apply v1.37.1
kubectl drain k8s-cp1 --ignore-daemonsets ; apt-get install -y kubelet=1.37.* kubectl=1.37.*
systemctl daemon-reload && systemctl restart kubelet ; kubectl uncordon k8s-cp1
# each worker, one at a time
apt-get install -y kubeadm=1.37.* ; kubeadm upgrade node
kubectl drain k8s-w1 --ignore-daemonsets --delete-emptydir-data   # waits for the PDB; storefront moves pod by pod
apt-get install -y kubelet=1.37.* kubectl=1.37.* ; systemctl restart kubelet ; kubectl uncordon k8s-w1
```
Zero downtime comes from: >= 2 replicas on different nodes, a readiness probe, a PDB that allows exactly one
disruption, a preStop delay for endpoint removal (P16), and draining one node at a time.

**Interview notes**
- Version skew: control plane first; kubelets may lag up to 3 minors behind the API server (never ahead).
- `kubeadm upgrade apply` renews the control-plane certificates; etcd and CoreDNS/kube-proxy are upgraded with it.
- Single-replica Deployments + PDB `minAvailable: 1` block drains the same way - the fix is more replicas, not a
  weaker budget.
