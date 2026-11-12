## Hint 1
`kubectl -n market get endpointslices -l kubernetes.io/service-name=web -o wide` - whose IPs are those?
`kubectl -n market get pods --show-labels`.

## Hint 2
A Service selects every pod whose labels match its selector, from any Deployment. `web`'s selector is
`app: web`, and `admin`'s pods carry `app: web` too.

## Hint 3
Make the selector specific: `role: frontend` is only on `web`'s pods -
`kubectl -n market patch svc web -p '{"spec":{"selector":{"app":"web","role":"frontend"}}}'`.
