sed -i 's|^          livenessProbe:|          startupProbe: {httpGet: {path: /health, port: http}, periodSeconds: 5, failureThreshold: 24}\n          livenessProbe:|' analytics.yaml
kx apply -f analytics.yaml >/dev/null
kx -n analytics rollout status deploy/analytics --timeout=240s >/dev/null
