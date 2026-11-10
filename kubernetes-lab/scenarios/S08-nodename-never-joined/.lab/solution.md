# S08 - nodeName of a node that isn't there

**Root cause**: `spec.nodeName: k8s-w4`. Setting nodeName skips the scheduler: the pod is already bound,
waiting for a kubelet called k8s-w4 that never registered. No scheduler, no events, Pending forever.

**Fix**: remove `nodeName`; use nodeSelector/affinity for placement.

**Interview notes**
- `nodeName` is what the scheduler writes; setting it by hand bypasses filters (resources, taints, affinity)
  - the kubelet may then reject the pod (OutOfcpu, NodeAffinity).
- Static pods and DaemonSets (via affinity since 1.12) are the legitimate "pinned" cases.
