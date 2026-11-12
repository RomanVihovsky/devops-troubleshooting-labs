# S14 - extended resources

**Root cause**: `trainer` requests `example.com/gpu: 1`. Extended resources are just counters on the Node
(`status.capacity` / `allocatable`). Nothing advertised one, so the scheduler found no node with enough.

**Diagnosis**
```
kubectl -n ml describe pod -l app=trainer | grep -A3 Events     # Insufficient example.com/gpu
kubectl get nodes -o custom-columns=NODE:.metadata.name,GPU:.status.allocatable.example\\.com/gpu
```

**Fix** (until the device plugin exists):
```
kubectl patch node k8s-w3 --subresource=status --type=json \
  -p '[{"op":"add","path":"/status/capacity/example.com~1gpu","value":"2"}]'
```

**Interview notes**
- Real accelerators: a **device plugin** (NVIDIA, AMD, Intel) registers with the kubelet, advertises
  `nvidia.com/gpu` and assigns devices to containers. Newer clusters use DRA (Dynamic Resource Allocation,
  ResourceClaims).
- Extended resources are integers, can't be overcommitted (request = limit), and are only counted. Nothing
  stops a container from using a card it didn't request.
- Patched capacity is not owned by the kubelet. Remove it when the plugin takes over (`op: remove`).
