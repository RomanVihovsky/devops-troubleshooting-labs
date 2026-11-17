# X08 - a dedicated Calico pool is too small

**Root cause**: namespace `batch` carries `cni.projectcalico.org/ipv4pools: ["batch-pool"]`, so Calico IPAM
assigns its pods addresses **only** from `batch-pool`: `10.250.0.0/29` - 8 addresses. Pods 9-12 get a sandbox
error (*Assigned 0 out of 1 requested IPv4 addresses; No IPs available in pools: [10.250.0.0/29]*) and retry forever.

**Diagnosis**
```
kubectl -n batch get pods -o wide | sort -k6          # ContainerCreating, no IP
kubectl -n batch describe pod <stuck>                  # FailedCreatePodSandBox ... calico ... allocate
kubectl get ns batch -o jsonpath='{.metadata.annotations}'
kubectl get ippools.crd.projectcalico.org -o custom-columns=NAME:.metadata.name,CIDR:.spec.cidr,BS:.spec.blockSize
kubectl get ipamblocks.crd.projectcalico.org          # which blocks exist, from which pool
```

**Fix**: an IPPool's CIDR is immutable - add a second pool from the reserved range and allow both:
```
kubectl apply -f batch-pool-2.yaml       # cidr 10.250.1.0/26, blockSize 26, same modes as batch-pool
kubectl annotate ns batch --overwrite cni.projectcalico.org/ipv4pools='["batch-pool","batch-pool-2"]'
kubectl -n batch delete pod --field-selector=status.phase=Pending
```

**Interview notes**
- Calico hands out IPs in **blocks** (default /26 per node); with `strictAffinity: false` a node may borrow from
  another node's block, so a pool's capacity is its CIDR, not blocks x nodes.
- Pool selection: pod annotation > namespace annotation > the pools whose `nodeSelector` matches the node.
- Without the Calico API server, IPPools are edited as `crd.projectcalico.org/v1` objects (or with
  `calicoctl`) - no defaulting or validation, so copy every field.
- The same symptom appears when the default pool is exhausted (too many pods for `/16` with `/26` blocks on many
  nodes) or a node's podCIDR range is too small with host-local IPAM.
