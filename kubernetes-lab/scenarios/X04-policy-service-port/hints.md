## Hint 1
`kubectl -n portx get svc web -o yaml` (port vs targetPort) and `kubectl -n portx describe networkpolicy web-ingress`.

## Hint 2
NetworkPolicy is enforced at the **pod**, after the Service's DNAT: it sees the pod's port (8080), not the Service
port (80).

## Hint 3
`ports: [{protocol: TCP, port: 8080}]` in the policy (or the named port `http`), apply.
