# X04 - policies see pod ports

**Root cause**: kube-proxy rewrites `web:80` to `<pod-ip>:8080` (DNAT) before the packet reaches the pod. The CNI
enforces NetworkPolicy at the pod's interface, on the translated destination: port **8080**. The policy allowed
80, which no packet at the pod ever carries.

**Diagnosis**
```
kubectl -n portx get svc web -o jsonpath='{.spec.ports}'; echo          # port 80 -> targetPort 8080
kubectl -n portx describe networkpolicy web-ingress
kubectl -n portx run t --rm -it --image=busybox:1.37 -- wget -T3 -qO- http://<pod-ip>:8080/   # same result: blocked
```

**Fix**: allow `8080` (or the container's named port; named ports follow the container spec).

**Interview notes**
- Egress has the same twist for Services: an egress rule to a ClusterIP is evaluated after DNAT, so you
  allow the **pods** (selectors) and their ports, not the Service IP. For the API server, the endpoint is
  192.168.56.21:6443, not 10.96.0.1:443 (T15).
- `endPort` allows ranges (`port: 8000, endPort: 8100`).
