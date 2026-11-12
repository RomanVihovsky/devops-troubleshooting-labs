# T06 · MetalLB + Ingress + Gateway API: three ways in from outside
**Learn** · LoadBalancer IPs on bare metal, L2 announcements, Traefik as Ingress controller and Gateway · ~30 min

`workspace/T06/t06.yaml` deploys `hello` (labapp) in namespace `t06`. Publish it to this desktop three ways
(finish the TODOs, `kubectl apply -f t06.yaml`):

1. A Service `hello-lb` of type **LoadBalancer** that gets exactly **192.168.56.210** from MetalLB's pool.
   MetalLB answers ARP for it from one node (layer 2): **which node** announces it? (`answers.yaml`)
2. An **Ingress** `hello` for host `t06.lab` through Traefik (its own LoadBalancer IP is 192.168.56.200).
3. An **HTTPRoute** `hello` for host `t06-gw.lab` attached to the Gateway `traefik-gateway` in namespace
   `traefik`.

Test from the desktop: `curl http://192.168.56.210/`, `curl -H 'Host: t06.lab' http://192.168.56.200/`,
`curl -H 'Host: t06-gw.lab' http://192.168.56.200/`.

**Test**: all three answer 200 from the desktop, the HTTPRoute is Accepted by the Gateway, and
`answers.yaml` names the announcing node.
