# X01 - default-deny egress also denies DNS

**Root cause**: `default-deny` (podSelector `{}`, Ingress + Egress) blocks all egress, DNS included. The allow rule
`client → backend:8080` is fine, but `client` reaches the backend **by name**: it first sends a DNS query to
CoreDNS (`kube-system`, port 53), and that query was dropped. The error is a name-resolution failure or timeout,
not a refused connection.

**Diagnosis**
```
kubectl -n zt exec deploy/client -- labapp get http://localhost:8080/upstream     # error: ... Name or service not known / timed out
kubectl -n zt get networkpolicy
kubectl -n zt exec deploy/client -- python3 -c 'import socket; print(socket.gethostbyname("backend.zt.svc.cluster.local"))'
```

**Fix**: a DNS egress allow for all pods in the namespace (UDP **and** TCP 53) to the CoreDNS pods, selected by
namespace + pod labels.

**Interview notes**
- Default-deny rollouts: always ship "allow DNS" in the same change. TCP 53 is needed for large responses
  (truncation, DNSSEC).
- NetworkPolicy works on IPs after resolution: you can't allow "backend.zt.svc", only pods/namespaces/CIDRs.
  FQDN policies need CNI extensions (Calico/Cilium).
- Policies are additive allow-lists per direction: a pod selected by any Egress policy is denied all egress
  except what some policy allows.
