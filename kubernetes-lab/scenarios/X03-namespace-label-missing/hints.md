## Hint 1
`kubectl -n appx describe networkpolicy allow-monitoring` - how does it recognise the monitoring namespace?

## Hint 2
`namespaceSelector` matches **namespace labels**. `kubectl get ns monitoring --show-labels`.

## Hint 3
`kubectl label namespace monitoring team=monitoring`.
