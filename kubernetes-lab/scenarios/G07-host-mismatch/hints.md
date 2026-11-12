## Hint 1
`kubectl -n store get ingress store -o jsonpath='{.spec.rules[*].host}'`. A 404 from the controller = no rule
matched the request's Host.

## Hint 2
An Ingress rule's `host` matches exactly (or a single-label wildcard `*.store.lab`). `www.store.lab` has no rule.

## Hint 3
Add a second rule for `www.store.lab` with the same backend (or a wildcard), apply.
