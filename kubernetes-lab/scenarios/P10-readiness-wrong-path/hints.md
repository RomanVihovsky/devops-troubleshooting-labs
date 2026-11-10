## Hint 1
`kubectl -n quotes describe pod <pod>` - the readiness probe's result. `kubectl -n quotes get endpointslices`.

## Hint 2
Which health endpoints does the app have? `kubectl -n quotes exec <pod> -- labapp get http://localhost:8080/ready`
(and `/health`, `/healthz`).

## Hint 3
labapp serves `/health` and `/ready` - not `/healthz`. Fix `readinessProbe.httpGet.path`, apply.
