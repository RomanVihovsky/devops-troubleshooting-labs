# N13 - ExternalName doesn't rename anything

**Root cause**: an ExternalName Service makes CoreDNS answer `search.frontend.svc.cluster.local` with a **CNAME**
to `search.vendor.svc.cluster.local`. That's all: the client still connects "to `search`", so
- TLS: it sends SNI `search` and verifies the certificate for `search` - the vendor's cert only lists
  `search.vendor.svc(.cluster.local)` -> *Hostname mismatch*;
- HTTP: it sends `Host: search`, which the vendor's virtual-host list rejects (404) even with verification off.
Setting `UPSTREAM_HOST` changes only the header, not SNI or the name being verified.

**Diagnosis**
```
kubectl -n frontend logs deploy/frontend | tail -3
kubectl -n frontend exec deploy/frontend -- labapp get https://search:8443/items --cacert /etc/lab-ca/ca.crt -v
kubectl -n vendor get secret search-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -ext subjectAltName
```

**Fix**: call the vendor by a name its certificate and virtual hosts know:
`UPSTREAM_URL=https://search.vendor.svc:8443/items`. To keep an alias for TLS services, the server's certificate
must include the alias (or use an in-cluster proxy/gateway that terminates and re-originates TLS).

**Interview notes**
- ExternalName has no selector, no endpoints, no ClusterIP, and no port mapping (`ports` are informational).
- Typical uses: an alias for an external DB hostname during a migration; never for IPs (use a selector-less
  Service + EndpointSlice).
- Ingress controllers that route to ExternalName backends must set the upstream Host/SNI explicitly.
