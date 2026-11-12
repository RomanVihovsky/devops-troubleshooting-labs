## Hint 1
`kubectl describe node k8s-cp1 | grep Taints`.

## Hint 2
DaemonSet pods get some tolerations automatically (not-ready, unreachable, disk-pressure, ...) - but not
for the control-plane taint.

## Hint 3
Add `tolerations: [{key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}]`
to the pod template, apply.
