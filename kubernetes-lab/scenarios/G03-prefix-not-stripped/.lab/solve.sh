kx apply -f - >/dev/null <<'YML'
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata: {name: strip-api, namespace: api-gw}
spec: {stripPrefix: {prefixes: [/api]}}
YML
kx -n api-gw annotate ingress items traefik.ingress.kubernetes.io/router.middlewares=api-gw-strip-api@kubernetescrd nginx.ingress.kubernetes.io/rewrite-target- --overwrite >/dev/null
