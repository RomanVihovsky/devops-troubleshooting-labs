# N04 - externalTrafficPolicy: Local without a pod on every node

**Root cause**: with `Local`, kube-proxy only forwards NodePort traffic to pods on the same node (and
drops it elsewhere) - to keep the client's source IP. One replica = one working node.

**Fix**: `externalTrafficPolicy: Cluster` (SNAT, any node forwards), or keep `Local` and run a pod on
every node that receives traffic (DaemonSet), or put a load balancer that health-checks
`healthCheckNodePort` in front.

**Interview notes**
- Cluster: works everywhere, client IP lost (SNAT), extra hop. Local: client IP kept, no extra hop, uneven
  load and dead nodes for the LB unless it health-checks.
- MetalLB/cloud LBs use `healthCheckNodePort` to only send traffic to nodes with local endpoints.
