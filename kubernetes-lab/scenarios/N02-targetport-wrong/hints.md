## Hint 1
`kubectl -n weather get endpointslices -o wide` - which port do the endpoints have?

## Hint 2
`port` is what clients use on the Service; `targetPort` is where the pod listens.

## Hint 3
`targetPort: 8080` (or the named port `http`), apply.
