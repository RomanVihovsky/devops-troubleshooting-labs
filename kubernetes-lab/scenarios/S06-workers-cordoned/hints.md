## Hint 1
`kubectl get nodes` - look at the STATUS column.

## Hint 2
`SchedulingDisabled` = cordoned (`spec.unschedulable: true`): `kubectl drain` cordons first, and someone
forgot the last step.

## Hint 3
`kubectl uncordon k8s-w1 k8s-w2 k8s-w3`.
