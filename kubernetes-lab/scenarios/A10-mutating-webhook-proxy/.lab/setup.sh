# A10: a mutating webhook appends HTTP(S)_PROXY to every pod in egress=guarded namespaces, no NO_PROXY
kns wallet security-system
kx label namespace wallet egress=guarded --overwrite >/dev/null
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger-api, namespace: wallet}
spec:
  replicas: 1
  selector: {matchLabels: {app: ledger-api}}
  template:
    metadata: {labels: {app: ledger-api}}
    spec:
      containers:
        - name: api
          image: registry.lab:5000/lab/labapp:1.4
          env: [{name: APP_NAME, value: ledger-api}]
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
---
apiVersion: v1
kind: Service
metadata: {name: ledger-api, namespace: wallet}
spec:
  selector: {app: ledger-api}
  ports: [{port: 8080, targetPort: 8080}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: wallet, namespace: wallet}
spec:
  replicas: 2
  selector: {matchLabels: {app: wallet}}
  template:
    metadata: {labels: {app: wallet}}
    spec:
      containers:
        - name: wallet
          image: registry.lab:5000/lab/labapp:1.4
          env:
            - {name: APP_NAME, value: wallet}
            - {name: UPSTREAM_URL, value: "http://ledger-api.wallet.svc:8080/items"}
            - {name: UPSTREAM_REQUIRED, value: "true"}
            - {name: HEALTH_CHECK_DEPENDENCIES, value: "true"}
          readinessProbe: {httpGet: {path: /ready, port: 8080}, periodSeconds: 3}
          livenessProbe: {httpGet: {path: /health, port: 8080}, periodSeconds: 5, failureThreshold: 2}
YML
wait_rollout wallet deploy/ledger-api; wait_rollout wallet deploy/wallet
# security's rollout
issue_cert a10-egress-guard DNS:egress-guard.security-system.svc
kx -n security-system create secret tls egress-guard-tls --cert="$CA_DIR/a10-egress-guard.crt" --key="$CA_DIR/a10-egress-guard.key" --dry-run=client -o yaml | ka -f -
ka -f egress-guard.yaml
wait_rollout security-system deploy/egress-guard
ka -f - <<YML
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata: {name: egress-guard}
webhooks:
  - name: proxy.egress-guard.lab
    clientConfig:
      service: {namespace: security-system, name: egress-guard, path: /mutate, port: 443}
      caBundle: $(base64 -w0 < "$CA_DIR/ca.crt")
    rules:
      - apiGroups: [""]
        apiVersions: [v1]
        operations: [CREATE]
        resources: [pods]
    namespaceSelector:
      matchLabels: {egress: guarded}
    failurePolicy: Fail
    sideEffects: None
    reinvocationPolicy: Never
    admissionReviewVersions: [v1]
    timeoutSeconds: 5
YML
sleep 3
kx -n wallet rollout restart deploy/wallet >/dev/null
proxied() { [ -n "$(kx -n wallet get pods -l app=wallet -o json | jq -r '.items[].spec.containers[0].env[]? | select(.name == "HTTPS_PROXY") | .value' | head -1)" ]; }
retry 60 proxied || die "no wallet pod got the proxy"
restarting() { [ "$(restarts wallet app=wallet)" -ge 1 ]; }
retry 120 restarting || die "the new wallet pods don't restart"
