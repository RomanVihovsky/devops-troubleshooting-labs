# G01 - an Ingress of a class nobody serves

**Root cause**: `ingressClassName: nginx`. Every ingress controller watches only the Ingresses of its own class
(`IngressClass.spec.controller`). This cluster runs Traefik (`traefik`, marked default), so nothing configured a
route, and Traefik's catch-all answered *404 page not found*.

**Diagnosis**
```
kubectl get ingressclass
kubectl -n gallery get ingress gallery         # CLASS nginx, no ADDRESS
curl -sv -H 'Host: gallery.lab' http://192.168.56.200/ 2>&1 | tail -3
```

**Fix**: `ingressClassName: traefik` (or omit it: the default IngressClass is used).

**Interview notes**
- An empty ADDRESS on an Ingress means no controller claimed it. The controller writes the LB address into
  `status.loadBalancer`.
- The old annotation `kubernetes.io/ingress.class` is deprecated; `spec.ingressClassName` replaced it.
- Moving between controllers (ingress-nginx → Traefik/Gateway API): annotations don't carry over
  (`nginx.ingress.kubernetes.io/rewrite-target` means nothing to Traefik: see G03).
