# A09: the webhook's readiness probe speaks HTTP to an HTTPS server -> no ready endpoints -> Fail closes orders
kns orders policy-system
kx label namespace orders policy=enforced --overwrite >/dev/null
issue_cert a09-pod-policy DNS:pod-policy.policy-system.svc
kx -n policy-system create secret tls pod-policy-tls --cert="$CA_DIR/a09-pod-policy.crt" --key="$CA_DIR/a09-pod-policy.key" --dry-run=client -o yaml | ka -f -
ka -f pod-policy.yaml
ka -f - <<YML
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata: {name: pod-policy}
webhooks:
  - name: pods.policy.lab
    clientConfig:
      service: {namespace: policy-system, name: pod-policy, path: /validate, port: 443}
      caBundle: $(base64 -w0 < "$CA_DIR/ca.crt")
    rules:
      - apiGroups: ["", "apps", "batch"]
        apiVersions: ["*"]
        operations: [CREATE, UPDATE]
        resources: [pods, deployments, statefulsets, jobs, configmaps, services]
    namespaceSelector:
      matchLabels: {policy: enforced}
    failurePolicy: Fail
    sideEffects: None
    admissionReviewVersions: [v1]
    timeoutSeconds: 5
YML
refused() { local o; o=$(kx -n orders create configmap lab-a09-try --dry-run=server 2>&1) && return 1; grep -q 'failed calling webhook' <<<"$o"; }
retry 60 refused || die "orders is not blocked by the webhook"
