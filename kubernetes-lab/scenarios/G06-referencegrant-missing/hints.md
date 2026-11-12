## Hint 1
`kubectl -n web-front get httproute frontdoor -o jsonpath='{.status.parents[*].conditions}' | jq`. Which
reference is not permitted, and who has to permit it?

## Hint 2
Cross-namespace references in Gateway API need a **ReferenceGrant** in the **target** namespace (the owner of the
Service agrees), naming the source kind/namespace and the target kind.

## Hint 3
In `web-back`: `kind: ReferenceGrant`, `spec.from: [{group: gateway.networking.k8s.io, kind: HTTPRoute,
namespace: web-front}]`, `spec.to: [{group: "", kind: Service}]`.
