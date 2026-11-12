# R06 - requests are reservations, not estimates

**Root cause**: each pod requested `6Gi` memory. The scheduler places pods by **requests**: a node fits a pod only
if allocatable minus the requests already placed there covers it. The workers have ~3.7 GiB allocatable, so no
node could ever fit one, however idle.

**Diagnosis**
```
kubectl -n analytics2 describe pod -l app=analytics | grep -A2 FailedScheduling   # Insufficient memory
kubectl describe node k8s-w1 | grep -A8 'Allocated resources'
kubectl get nodes -o custom-columns=NODE:.metadata.name,MEM:.status.allocatable.memory
```

**Fix**: requests from measured usage plus headroom (here 256Mi), a limit above that.

**Interview notes**
- Requests drive scheduling and bin-packing (and cost); usage drives OOMs and throttling. Right-size from
  data: `kubectl top`, Prometheus `container_memory_working_set_bytes`, the VPA in recommend mode.
- Over-requesting wastes the cluster (nodes look full while idle); under-requesting overcommits nodes and
  leads to evictions (R04).
- "Insufficient cpu/memory" = requests. "Too many pods" = maxPods (S12). "Untolerated taint" = taints (S03).
