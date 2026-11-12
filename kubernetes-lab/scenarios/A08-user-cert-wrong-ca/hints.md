## Hint 1
`openssl x509 -in workspace/A08/alice.crt -noout -subject -issuer` and compare the issuer with the cluster CA
(`kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d |
openssl x509 -noout -subject`). The API server ignores client certs from CAs it doesn't trust - you're anonymous.

## Hint 2
A CSR for alice from her key: `openssl req -new -key alice.key -subj "/CN=alice/O=dev-team" -out alice.csr`. Then a
`CertificateSigningRequest` object (`signerName: kubernetes.io/kube-apiserver-client`, `usages: [client auth]`),
approve it, fetch `.status.certificate`. (Learn lab T07 walks through it.)

## Hint 3
`kubectl config set-credentials alice --client-certificate=alice.crt --client-key=alice.key --embed-certs
--kubeconfig workspace/A08/kubeconfig` with the issued cert in `alice.crt`.
