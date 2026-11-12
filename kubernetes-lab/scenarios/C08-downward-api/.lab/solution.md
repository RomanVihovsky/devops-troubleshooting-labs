# C08 - two Downward API surprises

**Root cause**
1. `fieldPath: status.podIp`: field paths are case-sensitive and validated. The API rejected the whole
   Deployment (*Unsupported value: "status.podIp"*, followed by the list of supported values).
2. `resourceFieldRef: limits.memory` on a container **without** a memory limit doesn't fail: it reports the
   node's allocatable memory (~3.7 GiB here). The cache would have been sized for the whole node.

**Diagnosis**
```
kubectl apply -f workspace/C08/inventory.yaml          # the error lists the supported fieldPaths
kubectl explain pod.spec.containers.env.valueFrom.fieldRef
kubectl -n inventory exec deploy/inventory -- printenv MEMORY_LIMIT_MB   # after the first fix: ~3700
```

**Fix**: `status.podIP`, and `limits.memory: 256Mi` on the container.

**Interview notes**
- Env fieldRefs: `metadata.name/namespace/uid/labels['k']/annotations['k']`, `spec.nodeName`,
  `spec.serviceAccountName`, `status.podIP/podIPs/hostIP`. resourceFieldRef: `requests|limits.cpu|memory|
  ephemeral-storage` (with `divisor`).
- Downward API env is fixed at start. A `downwardAPI` **volume** updates labels/annotations live.
- Unset limits fall back to node allocatable. Apps that size heaps or caches from "their" limit (JVMs, Go's
  GOMEMLIMIT) need a real limit.
