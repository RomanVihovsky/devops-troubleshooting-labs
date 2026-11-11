# The API "is down" - except on the control-plane node itself
**INC-2392** · P1 · Reporter: on-call

Since the gateway maintenance (preparing `k8s-gw` for a second control-plane node) `kubectl` from every desktop
fails, and the nodes turn NotReady one after another. On `k8s-cp1` the API server runs happily (`crictl ps`),
and `kubectl --server https://192.168.56.21:6443 ...` there still works. Everything uses the API through the
load balancer on `k8s-gw` (`k8s-api.lab:6443` = 192.168.56.20).

**Test**: `kubectl` from the desktop works through `https://192.168.56.20:6443`; haproxy on `k8s-gw` sends the API
to `k8s-cp1` (192.168.56.21:6443) and reports that server UP; all nodes Ready.
