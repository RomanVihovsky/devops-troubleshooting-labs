kx apply -f - >/dev/null <<'YML'
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata: {name: web-front-routes, namespace: web-back}
spec:
  from: [{group: gateway.networking.k8s.io, kind: HTTPRoute, namespace: web-front}]
  to: [{group: "", kind: Service}]
YML
r() { [ "$(kx -n web-front get httproute frontdoor -o jsonpath='{.status.parents[*].conditions[?(@.type=="ResolvedRefs")].status}')" = True ]; }
retry 60 r || true
