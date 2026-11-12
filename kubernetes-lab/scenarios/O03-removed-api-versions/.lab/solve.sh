cat > extras.yaml <<'YML'
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: {name: web, namespace: legacyweb}
spec:
  minAvailable: 1
  selector: {matchLabels: {app: web}}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: web, namespace: legacyweb}
spec:
  rules:
    - host: legacy.lab
      http:
        paths:
          - path: /
            pathType: Prefix
            backend: {service: {name: web, port: {number: 8080}}}
YML
kx apply -f extras.yaml >/dev/null
