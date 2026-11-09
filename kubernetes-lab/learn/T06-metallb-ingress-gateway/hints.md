## Hint 1
`type: LoadBalancer` + the annotation `metallb.io/loadBalancerIPs: 192.168.56.210` (MetalLB ≥ 0.13;
`spec.loadBalancerIP` is deprecated). `kubectl -n metallb-system get ipaddresspools` shows the pool.

## Hint 2
`kubectl -n t06 describe svc hello-lb` - the events show `nodeAssigned ... announcing from node`; MetalLB
also keeps it in `kubectl -n metallb-system get servicel2statuses`.

## Hint 3
Ingress: `rules: [{host: t06.lab, http: {paths: [{path: /, pathType: Prefix, backend: {service: {name:
hello, port: {number: 80}}}}]}}]` (Traefik is the default IngressClass). HTTPRoute: `parentRefs: [{name:
traefik-gateway, namespace: traefik}]`, `hostnames: [t06-gw.lab]`, `rules: [{backendRefs: [{name: hello,
port: 80}]}]`; `kubectl -n t06 get httproute hello -o yaml` shows whether the Gateway accepted it.
