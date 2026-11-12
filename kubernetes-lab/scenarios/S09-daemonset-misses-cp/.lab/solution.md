# S09 - the DaemonSet doesn't tolerate the control-plane taint

**Root cause**: k8s-cp1 has `node-role.kubernetes.io/control-plane:NoSchedule`; the DaemonSet has no
matching toleration, so the DaemonSet controller doesn't even count that node (desired 3).

**Fix**: tolerate the control-plane taint.

**Interview notes**
- The DaemonSet controller adds tolerations for node conditions (not-ready, unreachable, memory/disk/pid
  pressure, unschedulable) - not for custom or role taints.
- Node agents (logs, metrics, CNI, CSI node plugins) usually tolerate everything:
  `tolerations: [{operator: Exists}]`.
