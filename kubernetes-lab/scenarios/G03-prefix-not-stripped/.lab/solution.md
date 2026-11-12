# G03 - a path prefix the app doesn't know

**Root cause**: the Ingress routes `/api/*` to `items`, which serves `/items`. With ingress-nginx the annotation
`rewrite-target` removed the prefix. Traefik ignores other controllers' annotations, so the app received
`/api/items` and answered its own 404.

**Diagnosis**
```
kubectl -n api-gw logs deploy/items --tail=5          # GET /api/items 404
kubectl -n api-gw get ingress items -o jsonpath='{.metadata.annotations}'; echo
```

**Fix**: a Traefik `Middleware` with `stripPrefix: {prefixes: [/api]}`, referenced by the router annotation
`traefik.ingress.kubernetes.io/router.middlewares: api-gw-strip-api@kubernetescrd` (`<ns>-<name>@kubernetescrd`).

**Interview notes**
- Controller-specific behaviour lives in annotations (or CRDs), and migrations silently drop it. Gateway API
  makes it portable: `HTTPRoute` filters `URLRewrite` with `ReplacePrefixMatch`.
- Strip vs rewrite: stripping `/api` from `/api/items` gives `/items`. Apps that generate links may need
  `X-Forwarded-Prefix` to build URLs back (Traefik sets it with stripPrefix).
- `pathType: Prefix` matches path segments (`/api` matches `/api/x`, not `/apix`). `ImplementationSpecific`
  differs per controller.
