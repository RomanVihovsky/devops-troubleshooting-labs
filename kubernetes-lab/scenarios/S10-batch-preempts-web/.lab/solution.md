# S10 - a high-priority batch preempts the web tier

**Root cause**: `batch-high` (value 1 000 000, `preemptionPolicy: PreemptLowerPriority` by default) lets a
pending batch pod **evict** lower-priority pods to make room. storefront has no PriorityClass (priority 0), and
`k8s-w2` has no room for both, so the scheduler preempts a storefront pod; its replacement stays Pending until the
batch ends.

**Diagnosis**
```
kubectl -n storefront get events --field-selector reason=Preempted
kubectl get priorityclass batch-high -o yaml          # no preemptionPolicy -> PreemptLowerPriority
kubectl get pods -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name,PRIO:.spec.priority | sort -k3 -n
kubectl describe node k8s-w2 | sed -n '/Allocated resources/,/Events/p'
```

**Fix** (the class value must stay):
- `preemptionPolicy: Never` on `batch-high`: batch pods still jump the scheduling queue but wait for room
  instead of evicting. The field is immutable - delete and re-create the class; pods keep the priority they were
  admitted with.
- or give storefront a PriorityClass with a higher value (`web-critical`, e.g. 2 000 000): the batch can't
  preempt pods of higher priority. Then the batch waits too.

**Interview notes**
- Preemption respects PDBs only on a best-effort basis - it will violate them if nothing else works.
- `system-cluster-critical` / `system-node-critical` (2e9) are reserved for the control plane and DaemonSets.
- Priority also orders the scheduling queue and (with QoS) the kubelet's eviction order under node pressure.
- `kubectl describe pod` of a preempted pod shows *Preempted by ... on node k8s-w2*.
