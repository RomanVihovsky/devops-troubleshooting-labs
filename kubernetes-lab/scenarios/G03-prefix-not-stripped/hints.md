## Hint 1
`kubectl -n api-gw logs deploy/items | tail` - which path does the app receive? Look at the Ingress's
annotations: which controller understands them?

## Hint 2
`nginx.ingress.kubernetes.io/rewrite-target` is an ingress-nginx annotation; Traefik ignores it. In Traefik a
path rewrite is a **Middleware** (`stripPrefix`), attached to the Ingress with
`traefik.ingress.kubernetes.io/router.middlewares: <namespace>-<name>@kubernetescrd`.

## Hint 3
```
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata: {name: strip-api, namespace: api-gw}
spec: {stripPrefix: {prefixes: [/api]}}
```
and on the Ingress: `traefik.ingress.kubernetes.io/router.middlewares: api-gw-strip-api@kubernetescrd`.
