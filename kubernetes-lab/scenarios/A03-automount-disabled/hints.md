## Hint 1
`kubectl -n janitor exec deploy/janitor -- ls /var/run/secrets/kubernetes.io/serviceaccount/` and
`kubectl -n janitor get sa janitor -o yaml`.

## Hint 2
`automountServiceAccountToken: false` on a ServiceAccount (or the pod spec) means no projected token
volume. The pod-level setting wins over the ServiceAccount's.

## Hint 3
`automountServiceAccountToken: true` in the janitor **pod template** (or on its own SA, not on `default`),
apply; the new pod gets the token.
