## Hint 1
`kubectl -n hpa describe hpa api` - read the conditions and events (`FailedGetResourceMetric`).

## Hint 2
CPU *utilization* is usage divided by the pod's CPU **request**. A container without a request has no
denominator, so the HPA can't compute a percentage (metrics-server works: `kubectl -n hpa top pods`).

## Hint 3
Give the container a CPU request, e.g. `kubectl -n hpa set resources deploy/api --requests=cpu=100m,memory=64Mi`
(or in `api.yaml`), and wait for the rollout. The HPA picks it up at its next sync.
