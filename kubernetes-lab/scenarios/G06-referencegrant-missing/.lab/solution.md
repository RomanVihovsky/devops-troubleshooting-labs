# G06 - cross-namespace references need consent

**Root cause**: the HTTPRoute in `web-front` refers to the Service `web-back/api`. Gateway API allows that only if
the **target** namespace grants it with a `ReferenceGrant`. Without one the reference doesn't resolve
(`ResolvedRefs=False, RefNotPermitted`), and requests get no backend.

**Diagnosis**
```
kubectl -n web-front get httproute frontdoor -o jsonpath='{.status.parents[0].conditions}' | jq
kubectl get referencegrants -A
```

**Fix** (in `web-back`, by its owners):
```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata: {name: web-front-routes, namespace: web-back}
spec:
  from: [{group: gateway.networking.k8s.io, kind: HTTPRoute, namespace: web-front}]
  to:   [{group: "", kind: Service}]          # optionally name: api
```

**Interview notes**
- The design is a confused-deputy guard: without the grant anyone could route traffic to (or read the TLS
  certificate Secret of) another team's namespace. The same mechanism applies to Gateways referencing
  certificate Secrets in other namespaces.
- Ingress has no cross-namespace backends at all. The usual workaround (ExternalName Services) has no consent
  model.
- Grants are additive and specific: from kind + namespace, to kind (+ optional name).
