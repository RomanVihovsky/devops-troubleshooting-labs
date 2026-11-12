# R04 - an eviction threshold above the free memory

**Root cause**: the "hardening" set `evictionHard: {memory.available: <N>Mi}` on `k8s-w2`, a value copied from
bigger nodes and **above** what this 4 GiB node has available after the OS and the system pods. The kubelet
saw permanent memory pressure: it set `MemoryPressure=True`, tainted the node `memory-pressure:NoSchedule`,
and evicted pods one after the other (BestEffort first, then Burstable pods by usage above their requests),
`payments-api` included. `free -m` looked fine because nothing was really short of memory.

**Diagnosis**
```
kubectl describe node k8s-w2 | grep -E 'MemoryPressure|Taints|Evict'
kubectl get --raw /api/v1/nodes/k8s-w2/proxy/stats/summary | jq '.node.memory | {availableBytes, workingSetBytes}'
./lab node w2; sudo grep -A3 evictionHard /var/lib/kubelet/config.yaml
kubectl -n payments get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass,STATUS:.status.phase,REASON:.status.reason
```

**Fix**
1. A sane threshold: drop `evictionHard` (default `memory.available<100Mi`) or e.g. `200Mi`; restart the kubelet.
2. Protect the critical service: requests = limits for every resource in every container → **Guaranteed**
   (`kubectl -n payments set resources deploy/payments-api --requests=cpu=100m,memory=256Mi --limits=cpu=100m,memory=256Mi`).

**Interview notes**
- Node-pressure eviction ranks pods by: exceeds requests? → priority → usage above requests. Guaranteed (and
  Burstable within requests) go last. A PriorityClass also helps.
- `memory.available` = capacity − the root cgroup's working set (not `free`'s "available"). Percent values
  make one config safe across node sizes.
- Setting `evictionHard` replaces the defaults for signals you don't list (nodefs, imagefs, inodes go to 0),
  unless the kubelet is told to merge them (`mergeDefaultEvictionSettings`). Set all of them on purpose.
- Soft thresholds (`evictionSoft` + grace periods) evict more gently; `systemReserved`/`kubeReserved` keep
  room for the OS so pressure rarely arises.
