## Hint 1
`kubectl -n legacy get svc db -o yaml` (no selector) and `kubectl -n legacy get endpointslices -l
kubernetes.io/service-name=db -o wide`. Which address is in there, and who has it?

## Hint 2
For a Service without a selector, nothing manages its EndpointSlices - they hold whatever someone wrote. Either
update the address, or give the Service a selector (then the EndpointSlice controller manages it).

## Hint 3
The robust fix: `kubectl -n legacy patch svc db -p '{"spec":{"selector":{"app":"pg-new"}}}'` and delete the
hand-made EndpointSlice (`kubectl -n legacy delete endpointslice db-manual`). The app reconnects by itself.
