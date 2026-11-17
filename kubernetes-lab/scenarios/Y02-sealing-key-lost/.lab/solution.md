# Y02 - the sealing key is the whole story

**Root cause**: Sealed Secrets encrypts with the controller's public key; only the private key in
`kube-system` (Secret labelled `sealedsecrets.bitnami.com/sealed-secrets-key`) decrypts. Deleting those Secrets and
restarting the controller made it generate a **new** key pair. Every existing SealedSecret - in Git and in the
cluster - is now undecryptable (*no key could decrypt secret*); as soon as a Secret is gone or the SealedSecret is
reconciled, the app loses it.

**Diagnosis**
```
kubectl get sealedsecrets -A                                  # SYNCED False
kubectl -n kube-system logs deploy/sealed-secrets-controller | grep -i decrypt
kubectl -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key   # only a brand-new key
```

**Fix**: restore the backup and restart the controller - it loads **all** keys it finds (old ones still decrypt, the
newest seals):
```
kubectl apply -f .state/sealed-secrets-key.yaml
kubectl -n kube-system rollout restart deploy/sealed-secrets-controller
```
No re-seal, no Git change.

**Interview notes**
- Back up the key (`kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml`)
  **outside** the cluster - it's the root of every sealed secret. Without it, the only way out is to re-create every
  plaintext and re-seal.
- Key renewal (every 30 days by default) adds keys, it never removes them; "old-looking" key Secrets are exactly
  the ones you need for old ciphertexts.
- Compare: ESO + an external store (Y-series) puts the root of trust outside the cluster.
