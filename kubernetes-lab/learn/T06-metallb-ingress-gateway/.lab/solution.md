# T06 - solution and takeaways

```yaml
metadata: {annotations: {metallb.io/loadBalancerIPs: 192.168.56.210}}   # Service hello-lb
spec: {type: LoadBalancer, ...}
---
kind: Ingress          # host t06.lab -> hello:80 (Traefik = default IngressClass)
---
kind: HTTPRoute        # parentRefs traefik/traefik-gateway, hostnames [t06-gw.lab], backendRefs hello:80
```
`kubectl -n metallb-system get servicel2statuses` (or the Service events) names the announcing node.

**Takeaways**
- Bare metal has no cloud load balancer: MetalLB hands out IPs from a pool and, in **layer 2** mode, one
  speaker (one node) answers ARP for each IP. That node carries all the traffic for it; if it dies, another
  speaker takes over after its memberlist notices (seconds). No real load balancing across nodes.
- `externalTrafficPolicy: Cluster` (default) hops to any node's pod and hides the client IP; `Local`
  keeps the client IP but only nodes with a ready pod may answer.
- Ingress vs Gateway API: same Traefik, two APIs. Gateway splits roles (the platform team owns the Gateway
  and its listeners, app teams attach Routes - `allowedRoutes` decides who may), and a Route reports
  whether it was **Accepted** - the first thing to check when a route "does nothing" (G domain).
