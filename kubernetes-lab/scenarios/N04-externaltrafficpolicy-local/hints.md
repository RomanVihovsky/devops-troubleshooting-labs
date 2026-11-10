## Hint 1
`curl -s -m 3 http://192.168.56.31:30480/` (and .32, .33). `kubectl -n kiosk get pods -o wide` - where is
the pod?

## Hint 2
`kubectl -n kiosk get svc kiosk -o yaml` - `externalTrafficPolicy`. With `Local`, a node only answers if
it has a ready pod itself (it keeps the client IP and never forwards).

## Hint 3
`externalTrafficPolicy: Cluster` (the default), apply. (Or run a pod on every node - a DaemonSet - if the
client IP must be kept.)
