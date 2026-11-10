# L12 - tolerationSeconds 3600 keeps pods on a dead node

**Root cause**: the Deployment brings its own tolerations for `node.kubernetes.io/unreachable` and
`not-ready` with `tolerationSeconds: 3600` ("flap protection"). When k8s-w2 died, the node controller
tainted it, but the pod tolerates the taint for an hour: it is not evicted, the ReplicaSet still counts it,
nothing replaces it.

**Fix**: tolerations of ≤ 120 s (or none: the DefaultTolerationSeconds admission plugin adds 300 s). The
rollout moves the pods to healthy nodes (the topology spread allows it: w2 is tainted NoSchedule too).

**Interview notes**
- Node failure timeline: kubelet stops posting → after `node-monitor-grace-period` (40 s) NotReady/Unknown
  + `unreachable` NoExecute taint → pods evicted after their tolerationSeconds (default 300 s).
- Short tolerations = faster failover but more churn on flapping networks; StatefulSets still need a
  human or the out-of-service taint (L11).
- Hard spreading rules (required anti-affinity, `DoNotSchedule` spread) can deadlock exactly this rollout:
  the healthy nodes already hold a pod, the dead node is tainted - prefer soft rules for stateless apps.
