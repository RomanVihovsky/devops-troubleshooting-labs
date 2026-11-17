## Hint 1
`kubectl -n frontend get svc search -o yaml`, then from a pod: `nslookup search` - what does an ExternalName
Service create in DNS? Which name does the client put into the TLS handshake (SNI) and the `Host` header?

## Hint 2
ExternalName is a DNS **CNAME** and nothing else: no proxy, no port mapping, no name rewriting. The client still
believes it talks to `search`, so it checks the certificate for `search` and sends `Host: search`. The vendor's
certificate is for `search.vendor.svc(.cluster.local)` only. `UPSTREAM_HOST` changes the header, not SNI.

## Hint 3
Call the name the certificate and the virtual host know: `UPSTREAM_URL=https://search.vendor.svc:8443/items`
(keep `UPSTREAM_CA_FILE`). An alias for TLS services only works if the server's certificate also lists the alias.
