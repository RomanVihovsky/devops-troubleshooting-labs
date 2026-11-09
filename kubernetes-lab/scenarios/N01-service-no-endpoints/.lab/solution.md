# N01 - Service selector doesn't match the pods

**Root cause**: the release renamed the pod label to `app: back-end`, but the Service still selects
`app: backend`. A Service with no matching pods has **no endpoints**: the ClusterIP exists, DNS resolves,
and every connection times out or is refused - while the pods themselves are perfectly healthy.

**Diagnosis**
```
kubectl -n orders get endpointslices -l kubernetes.io/service-name=backend   # ENDPOINTS: <none>
kubectl -n orders get svc backend -o jsonpath='{.spec.selector}'            # {"app":"backend"}
kubectl -n orders get pods --show-labels                                      # app=back-end
kubectl -n orders get pods -l app=backend                                     # No resources found
```

**Fix**: make the selector match: `kubectl -n orders patch svc backend -p '{"spec":{"selector":{"app":"back-end"}}}'`
(and fix the manifest in Git, or the next deploy brings the bug back).

**Interview notes**
- "Pods healthy, Service times out" -> check endpoints first; it's selector/labels, `targetPort`, or readiness.
- Endpoints only list **Ready** pods - a failing readiness probe also empties them.
- `kubectl describe svc` shows `Endpoints:`; EndpointSlices are the source of truth since 1.21.
- The Deployment's own `selector` is immutable; a Service selector is not - fix the Service, not the pods.
