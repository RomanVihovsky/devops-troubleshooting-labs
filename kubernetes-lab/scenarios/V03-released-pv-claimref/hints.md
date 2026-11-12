## Hint 1
`kubectl get pv orders-archive` - STATUS? `kubectl get pv orders-archive -o jsonpath='{.spec.claimRef}'`.

## Hint 2
A `Released` PV still remembers its old claim (namespace, name, **uid**). It won't bind to anything else
until that reference is gone - that's how Retain protects data.

## Hint 3
`kubectl patch pv orders-archive --type json -p '[{"op":"remove","path":"/spec/claimRef"}]'` - the PV turns
Available, the new claim binds.
