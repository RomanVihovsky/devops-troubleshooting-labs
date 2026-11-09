# T12: namespace t12 and legacy.yaml, sealed with the controller's current (= original) cert
kns t12
kx -n t12 create secret generic legacy --from-literal=password=0ld-but-g0ld --dry-run=client -o yaml \
  | kubeseal --cert "$SEALED_CERT" --format yaml --scope strict > legacy.yaml
remember t12_keys "$(kx -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key --no-headers | wc -l)"
