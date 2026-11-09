## Hint 1
```
kubectl -n t12 create secret generic api-key --from-literal=key=K3y-t12 --dry-run=client -o yaml \
  | kubeseal --format yaml --scope strict > api-key.sealed.yaml
```
`--scope namespace-wide` / `cluster-wide` add the annotations `sealedsecrets.bitnami.com/namespace-wide` /
`cluster-wide`; strict binds the encryption to the name and namespace.

## Hint 2
`kubectl -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml >
sealing-key.backup.yaml` - this file decrypts every SealedSecret in Git: treat it like a root password.

## Hint 3
Drill: `kubectl -n kube-system delete secret -l sealedsecrets.bitnami.com/sealed-secrets-key`,
`kubectl -n kube-system delete pod -l app.kubernetes.io/name=sealed-secrets`. Restore: `kubectl apply -f
sealing-key.backup.yaml` and restart the controller again; `kubectl -n t12 get sealedsecret legacy -o yaml`
shows the sync status.
