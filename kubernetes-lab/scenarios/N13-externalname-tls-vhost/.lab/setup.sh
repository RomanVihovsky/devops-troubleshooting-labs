# N13: ExternalName is only a CNAME - the client verifies the cert for "search" and sends Host: search
kns frontend vendor
issue_cert n13-search DNS:search.vendor.svc.cluster.local DNS:search.vendor.svc
kx -n vendor create secret tls search-tls --cert="$CA_DIR/n13-search.crt" --key="$CA_DIR/n13-search.key" --dry-run=client -o yaml | ka -f -
kx -n frontend create configmap lab-ca --from-file=ca.crt="$CA_DIR/ca.crt" --dry-run=client -o yaml | ka -f -
ka -f - <<'YML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: search, namespace: vendor}
spec:
  replicas: 1
  selector: {matchLabels: {app: search}}
  template:
    metadata: {labels: {app: search}}
    spec:
      containers:
        - name: search
          image: registry.lab:5000/lab/labapp:1.4
          env:
            - {name: APP_NAME, value: vendor-search}
            - {name: PORT, value: "8443"}
            - {name: TLS_CERT_FILE, value: /tls/tls.crt}
            - {name: TLS_KEY_FILE, value: /tls/tls.key}
            - {name: ALLOWED_HOSTS, value: "search.vendor.svc.cluster.local,search.vendor.svc"}
          readinessProbe: {httpGet: {path: /ready, port: 8443, scheme: HTTPS}, periodSeconds: 3}
          volumeMounts: [{name: tls, mountPath: /tls, readOnly: true}]
      volumes:
        - name: tls
          secret: {secretName: search-tls}
---
apiVersion: v1
kind: Service
metadata: {name: search, namespace: vendor}
spec:
  selector: {app: search}
  ports: [{port: 8443, targetPort: 8443}]
YML
wait_rollout vendor deploy/search
remember n13_vendor "$(kx -n vendor get deploy search -o jsonpath='{.spec.template.spec}' | sha256sum)"
remember n13_cert "$(kx -n vendor get secret search-tls -o jsonpath='{.data.tls\.crt}' | sha256sum)"
ka -f frontend.yaml
mismatch() { local o; o=$(kx -n frontend logs deploy/frontend --tail=40 2>/dev/null) || true; grep -qi 'hostname mismatch' <<<"$o"; }
retry 90 mismatch || die "frontend never logged the hostname mismatch"
