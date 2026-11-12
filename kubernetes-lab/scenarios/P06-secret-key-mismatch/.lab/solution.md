# P06 - the Secret has no such key

**Root cause**: `secretKeyRef: {name: ledger-db, key: password}`, but the rotated Secret has the key
`passwd`. The kubelet can't build the container's environment: CreateContainerConfigError (the container
is never created, so there are no logs).

**Diagnosis**: `kubectl describe pod` (couldn't find key password in Secret ledger/ledger-db),
`kubectl get secret ledger-db -o jsonpath='{.data}'`.

**Fix**: reference `passwd` (or, with the DBA team, agree on one key name).

**Interview notes**
- CreateContainerConfigError = config the kubelet can't resolve: missing Secret/ConfigMap/key, invalid
  `runAsNonRoot` vs image user (A05). The pod events say which.
- `optional: true` on the reference starts the pod without it - only for genuinely optional settings.
- Secrets in env vars don't update in running pods; files do (with a delay).
