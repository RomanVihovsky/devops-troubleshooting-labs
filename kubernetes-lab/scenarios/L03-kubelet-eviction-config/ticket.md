# k8s-w2 NotReady after the eviction tuning
**INC-2305** · P2 · Reporter: SRE

Yesterday we tuned the kubelet's hard eviction thresholds on k8s-w2 (`/var/lib/kubelet/config.yaml`):
evict when less than 200 megabytes of memory or 10 % of disk are left. Since the kubelet restart, k8s-w2 is
**NotReady** and the kubelet restarts every few seconds. Keep the tuning.

**Test**: kubelet active on k8s-w2, the node is Ready; its eviction thresholds are still memory.available
200 Mi (or 200 M) and nodefs.available 10 %.
