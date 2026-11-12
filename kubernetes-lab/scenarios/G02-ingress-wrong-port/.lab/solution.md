# G02 - an Ingress backend port the Service doesn't have

**Root cause**: the Ingress points at `catalog:80`, but the Service only defines port 8080. Traefik can't build the
backend (*service port not found*), skips the route, and answers 404 itself.

**Diagnosis**
```
kubectl -n catalog2 get ingress catalog -o jsonpath='{.spec.rules[0].http.paths[0].backend}'; echo
kubectl -n catalog2 get svc catalog -o jsonpath='{.spec.ports}'; echo
kubectl -n traefik logs deploy/traefik --since=10m | grep -i catalog2
```

**Fix**: `port: {number: 8080}` (or the port's name, `http`, which survives port-number changes).

**Interview notes**
- Three ports, three meanings: Ingress backend port = **Service** port, Service `targetPort` = container port, and
  `containerPort` is informational (except for named ports).
- 404 from the controller = no route; 503 = route, but no ready endpoints; 502/504 = the backend refused or
  timed out. ingress-nginx answers 503 for a missing Service port; Traefik skips the route (404). Read the
  controller's log.
