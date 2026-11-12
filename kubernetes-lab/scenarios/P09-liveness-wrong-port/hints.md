## Hint 1
`kubectl -n profile describe pod <pod>` - the Events: who kills the container, and why?

## Hint 2
Compare the liveness probe's port with the port the app listens on (the readiness probe works...).

## Hint 3
`livenessProbe.httpGet.port: 8080` (or the named port), apply.
