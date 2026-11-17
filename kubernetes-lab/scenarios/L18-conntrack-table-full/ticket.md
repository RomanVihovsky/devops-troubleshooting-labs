# Pods on k8s-w3 time out on new connections under load
**INC-2790** · P2 · Reporter: team pricing

Our load tests against `quotes` (namespace `quotes`) fail only when the load generator lands on `k8s-w3`: a chunk of
requests time out while connecting, at random. From `k8s-w1`/`k8s-w2` the same test is clean, the `quotes` pods are
idle. The node's kernel log has something to say. A "memory tuning for small VMs" was rolled out to w3 last week.

**Test**: on `k8s-w3`, `net.netfilter.nf_conntrack_max` is at least 131072 now **and after a reboot** (no sysctl
file lowers it); a 45 s load test from a pod on `k8s-w3` against `quotes` has no failed request.
