## Hint 1
`kubectl -n search get deploy search -o jsonpath='{.spec.selector}'` vs the v2 file. Which fields of a
Deployment can't change after creation?

## Hint 2
`spec.selector` of apps/v1 Deployments is immutable - a different selector means a different Deployment. The
same name is fine once the old one is gone.

## Hint 3
`kubectl -n search delete deploy search` then `kubectl apply -f workspace/W02/search-v2.yaml` (zero-downtime
alternative: create `search-v2` next to it, switch the Service, delete the old one).
