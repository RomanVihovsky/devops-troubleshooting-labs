# R08 - "DiskPressure" set by configuration

**Root cause**: the "tuning" set `evictionHard: {nodefs.available: <free+5>%}` on `k8s-w3`, demanding more free
disk than the node had. The kubelet saw disk pressure at once: `DiskPressure=True`, the
`disk-pressure:NoSchedule` taint, image garbage collection (cached images deleted), and eviction of pods by
their local storage use. `df` showed lots of free space because nothing filled the disk; the threshold was
wrong.

**Diagnosis**
```
kubectl describe node k8s-w3 | grep -E 'DiskPressure|Taints|FreeDiskSpace|Evict'
kubectl get --raw /api/v1/nodes/k8s-w3/proxy/stats/summary | jq '.node.fs | {availableBytes, capacityBytes}'
./lab node w3; df -h /; sudo grep -A3 evictionHard /var/lib/kubelet/config.yaml
```

**Fix**: drop `evictionHard` (defaults: `nodefs.available<10%`, `imagefs.available<15%`,
`nodefs.inodesFree<5%`, `memory.available<100Mi`) or set a sane value; restart the kubelet.

**Interview notes**
- Signals: `nodefs` (kubelet root, emptyDirs, logs), `imagefs` (container images/layers; on one disk it is
  the same filesystem), inodes. On disk pressure the kubelet first deletes unused images and dead containers,
  then evicts pods (by ephemeral-storage use above requests).
- Thresholds are "keep this much free". Read the number the other way round and you get this incident.
- Setting a partial `evictionHard` drops the defaults for the signals you leave out. List all of them.
- Real DiskPressure is usually logs, emptyDirs or images. L17 has the "deleted but still open" variant.
