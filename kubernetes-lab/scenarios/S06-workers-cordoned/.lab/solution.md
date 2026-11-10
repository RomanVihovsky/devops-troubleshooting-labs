# S06 - the nodes were never uncordoned

**Root cause**: all workers are cordoned (`kubectl drain` sets `spec.unschedulable`); the maintenance ended
without `kubectl uncordon`. Running pods stay, nothing new can be scheduled (only DaemonSet pods, which
tolerate it).

**Fix**: `kubectl uncordon` every worker.

**Interview notes**
- drain = cordon + evict (respecting PDBs); uncordon is a separate, forgettable step - automate it
  (kured, cluster-api, upgrade scripts).
- A cordoned node shows `Ready,SchedulingDisabled` and the taint `node.kubernetes.io/unschedulable`.
