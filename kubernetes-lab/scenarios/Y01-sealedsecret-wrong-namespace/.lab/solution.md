# Y01 - sealed for the wrong namespace

**Root cause**: the rotated token was sealed with `--namespace demo-staging` (strict scope) and committed for
demo. In `demo` the controller can't decrypt it ("no key could decrypt secret") and keeps the existing
Secret, so the **old** token stays active and the new one is rejected. In staging it decrypts fine - which
is why "it worked in staging".

**Diagnosis**
```
kubectl -n demo get sealedsecret demo-auth -o jsonpath='{.status.conditions}'
kubectl -n kube-system logs deploy/sealed-secrets-controller | grep demo-auth
```

**Fix**: reseal for `demo/demo-auth` (`kubeseal --raw --scope strict --namespace demo --name demo-auth`),
commit, push; the checksum annotation restarts the pods with the new token.

**Interview notes**
- Strict = bound to namespace + name (default); namespace-wide = any name in the namespace; cluster-wide =
  anywhere. The scope is part of the ciphertext - you can't "move" a SealedSecret, you reseal it.
- A failed decryption is silent for the app: the old Secret stays. Alert on the SealedSecret's Synced
  condition, not on pod health.
- Env vars from Secrets are read at start: a rotation needs a rollout (checksum annotations, Reloader) or
  mounting the Secret as a file.
