# L01 - kubelet stopped (and disabled) on a worker

**Root cause**: the patch runbook stopped the node services with `systemctl disable --now kubelet` and the
reboot step was skipped. Without kubelet nobody renews the node's Lease or posts its status; after the
node-monitor grace period the node controller marks it **NotReady** (`Unknown` conditions), taints it
`node.kubernetes.io/unreachable`, and after `tolerationSeconds` (300 s by default) evicts its pods.

**Diagnosis**
```
kubectl get nodes; kubectl describe node k8s-w2          # "Kubelet stopped posting node status"
./lab node w2
systemctl status kubelet                                 # inactive (dead), disabled
journalctl -u kubelet -n 20                              # the last lines are the stop, no crash
```

**Fix**: `sudo systemctl enable --now kubelet`. `start` alone fixes it until the next reboot - `enable`
makes it permanent.

**Interview notes**
- NotReady is a symptom: kubelet down, container runtime down, CNI not ready, the network partitioned
  from the API, a disk/PID pressure condition - the node's Conditions and kubelet's journal tell which.
- Node heartbeats are Lease objects in `kube-node-lease`; `kubectl get lease -n kube-node-lease`.
- What happens to the pods: Deployments get replacements elsewhere after ~5 min; StatefulSet pods stay
  `Terminating` until the node is back or deleted (no two pods with the same identity).
