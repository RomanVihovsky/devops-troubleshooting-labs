kx apply -f - >/dev/null <<'YML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-dns, namespace: shop}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}, podSelector: {matchLabels: {k8s-app: kube-dns}}}]
      ports: [{protocol: UDP, port: 53}, {protocol: TCP, port: 53}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: frontend, namespace: shop}
spec:
  podSelector: {matchLabels: {app.kubernetes.io/name: frontend}}
  policyTypes: [Ingress, Egress]
  ingress: [{from: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: traefik}}}], ports: [{port: 8080}]}]
  egress: [{to: [{podSelector: {matchLabels: {app.kubernetes.io/name: api}}}], ports: [{port: 8080}]}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: api, namespace: shop}
spec:
  podSelector: {matchLabels: {app.kubernetes.io/name: api}}
  policyTypes: [Ingress, Egress]
  ingress: [{from: [{podSelector: {matchLabels: {app.kubernetes.io/name: frontend}}}], ports: [{port: 8080}]}]
  egress:
    - {to: [{podSelector: {matchLabels: {app.kubernetes.io/name: postgres}}}], ports: [{port: 5432}]}
    - {to: [{podSelector: {matchLabels: {app.kubernetes.io/name: redis}}}], ports: [{port: 6379}]}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: db, namespace: shop}
spec:
  podSelector: {matchExpressions: [{key: app.kubernetes.io/name, operator: In, values: [postgres, redis]}]}
  policyTypes: [Ingress]
  ingress: [{from: [{podSelector: {matchLabels: {app.kubernetes.io/name: api}}}]}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: eso-egress, namespace: external-secrets}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}, podSelector: {matchLabels: {k8s-app: kube-dns}}}]
      ports: [{protocol: UDP, port: 53}, {protocol: TCP, port: 53}]
    - {to: [{ipBlock: {cidr: 192.168.56.21/32}}], ports: [{port: 6443}]}
    - {to: [{ipBlock: {cidr: 192.168.56.20/32}}], ports: [{port: 8200}]}
YML
retry 120 shop_ok || true
