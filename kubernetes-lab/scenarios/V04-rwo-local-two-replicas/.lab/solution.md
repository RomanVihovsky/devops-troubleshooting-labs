# V04 - one RWO local volume, two replicas on two nodes

**Root cause**: both replicas mount the same claim. local-path binds it to the node of the first pod
(`WaitForFirstConsumer` + PV nodeAffinity); the required anti-affinity forbids the second pod there, and
every other node conflicts with the PV's node affinity.

**Fix**: per-replica volumes - a StatefulSet with `volumeClaimTemplates` (or RWX storage if the cache may be
shared).

**Interview notes**
- RWO = one node, not one pod: two pods on the same node can share an RWO volume - with local storage the
  scheduler places them together, which the anti-affinity forbids here.
- StatefulSet PVCs survive scale-down and pod deletion (`persistentVolumeClaimRetentionPolicy` to change).
