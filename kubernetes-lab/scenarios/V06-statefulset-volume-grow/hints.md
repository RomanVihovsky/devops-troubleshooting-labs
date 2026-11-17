## Hint 1
`kubectl -n metrics get pvc` and `kubectl get sc nfs -o yaml` (`allowVolumeExpansion`). The StatefulSet only
**creates** PVCs from its template - the existing PVCs are separate objects. Can you resize those directly?

## Hint 2
Resize each PVC: `kubectl -n metrics patch pvc data-tsdb-0 -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'`
(and `-1`). That fixes today's disks. The template is still immutable for the next replicas...

## Hint 3
Delete only the StatefulSet object and leave its pods and PVCs running: `kubectl -n metrics delete sts tsdb
--cascade=orphan`, then apply the manifest with 2Gi. The new StatefulSet adopts the pods and PVCs.
