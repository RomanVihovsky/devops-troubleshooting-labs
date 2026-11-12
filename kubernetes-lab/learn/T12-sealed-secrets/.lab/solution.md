# T12 - solution and takeaways

```
kubeseal --fetch-cert > pub.pem
kubectl -n t12 create secret generic api-key --from-literal=key=K3y-t12 --dry-run=client -o yaml \
  | kubeseal --format yaml --scope strict > api-key.sealed.yaml          # + namespace-wide, cluster-wide
kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealing-key.backup.yaml
kubectl -n kube-system delete secret -l sealedsecrets.bitnami.com/sealed-secrets-key     # drill
kubectl -n kube-system delete pod -l app.kubernetes.io/name=sealed-secrets               # new key
kubectl apply -f legacy.yaml                     # "no key could decrypt secret"
kubectl apply -f sealing-key.backup.yaml         # restore (strip resourceVersion/uid if apply complains)
kubectl -n kube-system delete pod -l app.kubernetes.io/name=sealed-secrets               # reload keys
```

**Takeaways**
- A SealedSecret is encrypted with the controller's public key; only the cluster's private key opens it.
  Scope is part of the encryption: strict (name + namespace), namespace-wide, cluster-wide. Renaming a
  strict secret breaks it on purpose.
- The controller keeps **all** its keys (it renews every 30 days by default and never deletes old ones),
  so old SealedSecrets keep working. Lose the keys = every SealedSecret in Git is garbage (Y02).
- Back up the key Secrets (encrypted, offline) and restore them **before** the controller starts on a new
  cluster - this lab's `./lab gitops stack` does exactly that.
- Re-encrypting a Secret (rotation of the *value*) means a new SealedSecret commit; rotating the *key*
  doesn't re-encrypt anything by itself (`kubeseal --re-encrypt`).
