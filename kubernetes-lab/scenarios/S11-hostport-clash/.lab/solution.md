# S11 - two pods want the same host port

**Root cause**: edge-proxy asks for `hostPort: 9100`, which node-probe already holds on every worker. A host
port can be bound by one pod per node: the scheduler's NodePorts filter rejects all nodes.

**Fix**: drop the hostPort - clients use the Service; hostPort was never needed.

**Interview notes**
- `hostPort` = a port on the node IP mapped to the pod (CNI portmap); `hostNetwork` = the pod uses the
  node's network namespace (all ports). Both limit you to one such pod per node.
- Prefer Services (ClusterIP/NodePort/LoadBalancer) or Ingress/Gateway; hostPort is for node agents.
