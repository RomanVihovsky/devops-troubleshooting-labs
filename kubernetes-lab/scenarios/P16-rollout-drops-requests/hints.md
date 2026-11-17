## Hint 1
Watch a rollout: `kubectl -n checkout rollout restart deploy/checkout-api` and in another shell
`kubectl -n checkout get endpointslices -w`. What does the old pod do the moment it is told to stop, and when do
the Service's endpoints stop sending it traffic?

## Hint 2
Deleting a pod starts two things **in parallel**: the kubelet sends SIGTERM, and the endpoint controller +
kube-proxy remove the pod from the Service. `SHUTDOWN_MODE=immediate` exits at once - requests in flight and
requests still routed to the old IP fail.

## Hint 3
Give the endpoints time to drain before the app sees SIGTERM: a `lifecycle.preStop` hook
(`exec: {command: ["sleep", "10"]}`), within `terminationGracePeriodSeconds`. (A graceful app setting -
`SHUTDOWN_MODE=graceful` plus `SHUTDOWN_DELAY_SECONDS` - also works.)
