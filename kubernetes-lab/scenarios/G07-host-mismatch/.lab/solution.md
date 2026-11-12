# G07 - Host matching

**Root cause**: the Ingress had a rule only for `store.lab`. Ingress matches the request's `Host` header against
`rules[].host` exactly (or a single-label wildcard). `www.store.lab` matched nothing, and Traefik answered 404.

**Diagnosis**
```
kubectl -n store get ingress store
curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: www.store.lab' http://192.168.56.200/
```

**Fix**: a rule for `www.store.lab` too (or `*.store.lab`, which does not match the bare `store.lab`).

**Interview notes**
- Wildcards cover exactly one label: `*.store.lab` matches `www.store.lab`, not `a.b.store.lab` or
  `store.lab`.
- The certificate must cover both names as well (SANs), or a redirect `www` → bare domain (Traefik
  `redirectRegex` middleware).
- An app can also reject hosts itself (labapp `ALLOWED_HOSTS`, Django `ALLOWED_HOSTS`): then the 404 comes
  from the app, not the controller. Compare the response bodies.
