## Hint 1
Default deny breaks name resolution first: `kubectl -n shop exec deploy/api -- python3 -c "import socket;
print(socket.gethostbyname('redis'))"`. Every pod needs egress to kube-system/kube-dns on 53 UDP+TCP.

## Hint 2
Then the flows, each with egress on the client side **and** ingress on the server side: Traefik (namespace
`traefik`) → frontend:8080 → api:8080 → postgres:5432 / redis:6379.

## Hint 3
ESO needs DNS, OpenBao (`bao.lab` = 192.168.56.20:8200) and the Kubernetes API. Policies see the API's
**post-DNAT** endpoint: `ipBlock 192.168.56.21/32` port 6443, not 10.96.0.1:443. Test with `kubectl -n shop
annotate externalsecret shop-secrets force-sync=$(date +%s) --overwrite`.
