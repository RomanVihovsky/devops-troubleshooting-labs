# DiskPressure on k8s-w3 with a mostly empty disk
**INC-2424** · P2 · Reporter: team ingest

`k8s-w3` reports `DiskPressure`. Its pods were evicted, our `ingest` workers (pinned to `k8s-w3` for their
local scratch disk) stay Pending, and the node deleted cached images. `df -h /` on the node says ~75% free.
The kubelet configuration on `k8s-w3` was "tuned" yesterday.

**Test**: `k8s-w3` has no DiskPressure, and its kubelet's `nodefs.available` hard eviction threshold is sane (at
most 15%, or the default); `ingest` runs 2 Ready pods on `k8s-w3`; all nodes Ready.
