# X09: security's default-deny policies; nothing else allowed
ka -f - <<'YML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny, namespace: shop}
spec: {podSelector: {}, policyTypes: [Ingress, Egress]}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-egress, namespace: external-secrets}
spec: {podSelector: {}, policyTypes: [Egress]}
YML
down() { ! shop_ok; }
retry 120 down || die "shop still works with default deny"
