## Hint 1
`kubectl -n catalog2 get svc catalog -o yaml` (ports) vs `kubectl -n catalog2 get ingress catalog -o yaml`
(the backend's `service.port`).

## Hint 2
An Ingress backend names a **Service port** (number or name), not the container port. The Service has only 8080.

## Hint 3
`port: {number: 8080}` (or `port: {name: http}`) in the Ingress, apply.
