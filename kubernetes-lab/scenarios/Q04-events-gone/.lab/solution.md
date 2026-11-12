# Q04 - forensics without events

**Facts**: the release changed the image `labapp:1.3` → `labapp:1.5` (revision 3), and 1.5 exits with code 1:
*required setting SESSION_SECRET is not set*. The last good image is `labapp:1.3` (revision 2), not 1.4 (that
was revision 1).

**What Kubernetes keeps when events are gone**
```
kubectl -n incident rollout history deploy/api                 # revisions (CHANGE-CAUSE if annotated)
kubectl -n incident get rs -o custom-columns=REV:.metadata.annotations.deployment\.kubernetes\.io/revision,IMAGE:.spec.template.spec.containers[0].image,CREATED:.metadata.creationTimestamp
kubectl -n incident logs <pod> --previous                      # the crash message
kubectl -n incident get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState}'
kubectl -n incident get deploy api -o jsonpath='{.status.conditions}'
```

**Interview notes**
- Events live `--event-ttl` (1 h) in etcd. Ship them (kube-eventrouter, the OTel k8s events receiver, Loki)
  if post-mortems need them.
- ReplicaSets are the deployment history (`revisionHistoryLimit`, W11). Their `creationTimestamp` dates each
  rollout.
- Timestamps that survive: `lastState.terminated.startedAt/finishedAt`, `status.conditions[].lastTransitionTime`,
  ReplicaSet creation, container `startedAt`.
