## Hint 1
`kubectl -n nightly get pod -l app=reporting -o yaml` - each container has a `lastState`.
`kubectl -n nightly describe pod -l app=reporting` shows it as "Last State".

## Hint 2
Look at **every** container of the pod (there are two) - only one has restarts.

## Hint 3
`kubectl -n nightly get pod -l app=reporting -o jsonpath='{range .status.containerStatuses[*]}{.name} {.restartCount}
{.lastState.terminated.reason} {.lastState.terminated.exitCode}{"\n"}{end}'` and the limit from `.spec.containers[*].resources`.
