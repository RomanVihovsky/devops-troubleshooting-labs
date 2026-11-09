cat >> shop.yaml <<'YML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: frontend, namespace: shop}
spec:
  podSelector: {matchLabels: {app.kubernetes.io/name: frontend}}
  policyTypes: [Ingress, Egress]
  ingress:
    - from: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: traefik}}}]
      ports: [{port: 8080}]
  egress:
    - to: [{podSelector: {matchLabels: {app.kubernetes.io/name: api}}}]
      ports: [{port: 8080}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: api, namespace: shop}
spec:
  podSelector: {matchLabels: {app.kubernetes.io/name: api}}
  policyTypes: [Ingress, Egress]
  ingress:
    - from: [{podSelector: {matchLabels: {app.kubernetes.io/name: frontend}}}]
      ports: [{port: 8080}]
  egress:
    - to: [{podSelector: {matchLabels: {app.kubernetes.io/name: postgres}}}]
      ports: [{port: 5432}]
    - to: [{podSelector: {matchLabels: {app.kubernetes.io/name: redis}}}]
      ports: [{port: 6379}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: postgres, namespace: shop}
spec:
  podSelector: {matchLabels: {app.kubernetes.io/name: postgres}}
  policyTypes: [Ingress]
  ingress:
    - from: [{podSelector: {matchLabels: {app.kubernetes.io/name: api}}}]
      ports: [{port: 5432}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: redis, namespace: shop}
spec:
  podSelector: {matchLabels: {app.kubernetes.io/name: redis}}
  policyTypes: [Ingress]
  ingress:
    - from: [{podSelector: {matchLabels: {app.kubernetes.io/name: api}}}]
      ports: [{port: 6379}]
YML
egress() {   # egress <ns> <extra rules yaml>: default-deny egress + DNS + the API (post-DNAT) + extras
  cat <<YML
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: egress, namespace: $1}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}, podSelector: {matchLabels: {k8s-app: kube-dns}}}]
      ports: [{protocol: UDP, port: 53}, {protocol: TCP, port: 53}]
    - to: [{ipBlock: {cidr: 192.168.56.21/32}}]
      ports: [{port: 6443}]
$2
YML
}
egress external-secrets '    - to: [{ipBlock: {cidr: 192.168.56.20/32}}]
      ports: [{port: 8200}]' > external-secrets.yaml
egress argocd '    - to: [{podSelector: {}}]
    - to: [{ipBlock: {cidr: 192.168.56.20/32}}]
      ports: [{port: 3000}]' > argocd.yaml
kx apply -f shop.yaml -f external-secrets.yaml -f argocd.yaml >/dev/null
retry 90 shop_ok || true
