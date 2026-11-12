# W06 - DaemonSets and taints

**Root cause**: ops tainted `k8s-w1` and `k8s-w2` with `maintenance=true:NoExecute`. The DaemonSet controller
schedules its pods with the normal taint rules (it adds tolerations only for `node.kubernetes.io/*` conditions
such as not-ready, disk-pressure, unschedulable). `NoExecute` evicted the agents running there, and no new
ones could start.

**Diagnosis**
```
kubectl -n logging get ds log-agent           # DESIRED 1
kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINTS:.spec.taints
```

**Fix**: `tolerations: [{key: maintenance, operator: Exists, effect: NoExecute}]` in the DaemonSet's template.

**Interview notes**
- Effects: `NoSchedule` (don't place new pods), `PreferNoSchedule`, `NoExecute` (also evict running pods,
  after `tolerationSeconds` if set).
- Node agents (logs, metrics, CNI, CSI) usually tolerate everything: `- operator: Exists`. That's why
  calico-node still runs on a tainted node.
- `kubectl drain` cordons (`unschedulable`) and evicts, but DaemonSet pods are skipped
  (`--ignore-daemonsets`) and the cordon taint is tolerated by them.
