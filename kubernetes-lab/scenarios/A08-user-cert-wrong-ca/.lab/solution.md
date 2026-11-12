# A08 - a client certificate from a CA the cluster doesn't trust

**Root cause**: alice's certificate was signed by a self-made "team CA". The API server authenticates client
certificates only against its `--client-ca-file` (the cluster CA). An unknown issuer means the certificate is
ignored, the request is anonymous, and the result is `Unauthorized`.

**Diagnosis**
```
openssl x509 -in workspace/A08/alice.crt -noout -subject -issuer          # issuer CN=team-ca
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d | openssl x509 -noout -subject
KUBECONFIG=workspace/A08/kubeconfig kubectl auth whoami                   # Unauthorized
```

**Fix** (her key never leaves her machine; only the CSR travels):
```
openssl req -new -key alice.key -subj "/CN=alice/O=dev-team" -out alice.csr
# CertificateSigningRequest: signerName kubernetes.io/kube-apiserver-client, usages [client auth], request: $(base64 -w0 alice.csr)
kubectl certificate approve alice
kubectl get csr alice -o jsonpath='{.status.certificate}' | base64 -d > alice.crt
kubectl config set-credentials alice --client-certificate=alice.crt --client-key=alice.key --embed-certs --kubeconfig ...
```

**Interview notes**
- Certificate users: CN = user name, O = groups. Kubernetes has **no revocation** for client certs. A leaked
  cert works until it expires, so keep `expirationSeconds` short and prefer OIDC for humans.
- Never put `O=system:masters` in a user cert: that group bypasses RBAC and can't be revoked.
- Authentication (who are you: cert/token/OIDC) and authorization (RBAC: what may you do) are separate.
  `Unauthorized` (401) is the first, `Forbidden` (403) the second.
