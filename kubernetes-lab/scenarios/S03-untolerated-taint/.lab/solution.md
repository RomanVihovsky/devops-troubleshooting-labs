# S03 - taints need tolerations

**Root cause**: every worker has `dedicated=batch:NoSchedule`; the etl pods have no toleration (and the
control plane has its own taint). No node is feasible.

**Fix**: a matching toleration in the pod template.

**Interview notes**
- Taints repel, tolerations allow - they don't attract. To *pin* batch pods to these nodes you also need
  a nodeSelector/affinity on a label.
- Effects: NoSchedule (new pods), PreferNoSchedule (soft), NoExecute (also evicts running pods - used by
  the node controller for not-ready/unreachable, L12).
- Removing the taint "to make it work" breaks the platform team's isolation.
