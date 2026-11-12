## Hint 1
Events are short-lived (1 h by default), but the Deployment's **ReplicaSets** remain:
`kubectl -n incident get rs -o wide` (images, revisions: `deployment.kubernetes.io/revision` annotation).

## Hint 2
A crash-looping container keeps its previous run: `kubectl -n incident logs <pod> --previous` and
`.status.containerStatuses[].lastState.terminated`.

## Hint 3
`kubectl -n incident rollout history deploy/api`, `kubectl -n incident get rs -o
custom-columns=NAME:.metadata.name,REV:.metadata.annotations.deployment\.kubernetes\.io/revision,IMAGE:.spec.template.spec.containers[0].image`.
