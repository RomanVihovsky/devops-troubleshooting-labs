## Hint 1
Who answers the 413 - the app or the ingress? `kubectl -n media logs deploy/media | grep upload`, and the
Ingress's annotations.

## Hint 2
A Traefik `Middleware` of type `buffering` with `maxRequestBodyBytes` is attached to the router
(`kubectl -n media get middleware -o yaml`).

## Hint 3
`kubectl -n media patch middleware upload-limit --type merge -p '{"spec":{"buffering":{"maxRequestBodyBytes":16777216}}}'`
(16 MiB).
