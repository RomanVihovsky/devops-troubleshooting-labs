# No logs from k8s-w1 and k8s-w2
**INC-2487** · P2 · Reporter: observability

Since this morning's maintenance prep we get no logs from `k8s-w1` and `k8s-w2`: the `log-agent` DaemonSet
(`logging`, `workspace/W06/log-agent.yaml`) has pods on `k8s-w3` only. Ops tainted w1 and w2 on purpose to drain
application pods for tomorrow's maintenance - the taints stay. The log agent must run on every worker regardless.

**Test**: `log-agent` runs a Ready pod on each of the 3 workers; the `maintenance` taints on `k8s-w1` and
`k8s-w2` are still there.
