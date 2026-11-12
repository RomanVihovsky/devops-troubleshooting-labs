# G04 - a TLS Secret in the wrong namespace

**Root cause**: `secure-tls` was created in `default` (the context's namespace); the Ingress is in `secure`.
`spec.tls[].secretName` is resolved in the Ingress's own namespace. Traefik didn't find it, logged an error, and
served its built-in self-signed *TRAEFIK DEFAULT CERT* for that host.

**Diagnosis**
```
curl -sv --resolve secure.lab:443:192.168.56.200 https://secure.lab/ 2>&1 | grep -E 'subject:|issuer:'
kubectl get secret -A --field-selector type=kubernetes.io/tls | grep secure-tls
kubectl -n traefik logs deploy/traefik --since=10m | grep -i secure-tls
```

**Fix**: create the TLS Secret in `secure` (and remove the stray copy).

**Interview notes**
- Other reasons for the default cert: the Secret's cert doesn't cover the requested host (SNI), key and cert
  don't match, or the client sent no SNI (curl to an IP).
- cert-manager does this for you: a `Certificate` (or the Ingress annotation `cert-manager.io/cluster-issuer`)
  writes the Secret into the right namespace and renews it.
- With Gateway API the certificate belongs to the **Gateway listener** (`certificateRefs`). Cross-namespace
  references need a ReferenceGrant (G06).
