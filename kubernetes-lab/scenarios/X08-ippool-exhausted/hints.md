## Hint 1
`kubectl -n batch describe pod <a ContainerCreating pod>` - the sandbox event says why. Then
`kubectl get ippools.crd.projectcalico.org -o yaml` and `kubectl get ns batch -o yaml` (annotations).

## Hint 2
`cni.projectcalico.org/ipv4pools` on the namespace pins its pods to `batch-pool`: a `/29` = 8 addresses for 12
pods. A pool's CIDR can't be changed after creation; you can create **another** pool and list both.

## Hint 3
Create e.g. `batch-pool-2` with `cidr: 10.250.1.0/26` (copy every field of `batch-pool`, blockSize 26), then
`kubectl annotate ns batch --overwrite cni.projectcalico.org/ipv4pools='["batch-pool","batch-pool-2"]'` and
delete the stuck pods (the annotation is read when a pod's sandbox is created).
