# N10 - a Service without a selector keeps pointing where it was told

**Root cause**: `db` has no selector, so the EndpointSlice controller ignores it, and its endpoints are
whatever is in the hand-made EndpointSlice `db-manual`: the old database's address. After the old database
was shut down, every connection to `db:5432` went to a dead IP, and the app's readiness (which checks the
database) failed.

**Diagnosis**
```
kubectl -n legacy get svc db -o jsonpath='{.spec.selector}'; echo     # empty
kubectl -n legacy get endpointslices -l kubernetes.io/service-name=db -o wide
kubectl -n legacy get pods -o wide                                     # whose IP was that?
kubectl -n legacy exec deploy/orders -- labapp get http://localhost:8080/ready
```

**Fix**: let Kubernetes manage it: selector `app: pg-new` on `db`, delete `db-manual`. (Writing pg-new's pod IP
into the slice "works" until that pod restarts with a new IP.)

**Interview notes**
- Selector-less Services are for things outside the cluster (a VM, a managed database) or for migrations, as
  here. Endpoints are then your job.
- `ExternalName` is the DNS-only alternative (CNAME): no proxying, no ports, no health. TLS/Host problems
  are N13.
- The label `kubernetes.io/service-name` ties a slice to a Service. Slices with
  `endpointslice.kubernetes.io/managed-by` set by the controller are rewritten. Hand-made ones are not.
- Readiness that checks the database keeps traffic away from broken pods, but if every pod fails, the
  Service has no endpoints at all. Decide which dependencies belong in readiness.
