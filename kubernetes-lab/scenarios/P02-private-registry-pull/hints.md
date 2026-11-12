## Hint 1
`kubectl -n vendor describe pod -l app=vendor-api` - the Events. Then `kubectl get secrets -A | grep regcred`:
where does it live, and which type is it?

## Hint 2
`imagePullSecrets` are looked up in the **pod's namespace** - a Secret in `ci` can't be used by a pod in `vendor`.
And the pod must reference it (or its ServiceAccount must).

## Hint 3
Copy it: `kubectl -n ci get secret regcred -o json | jq 'del(.metadata.namespace,.metadata.uid,
.metadata.resourceVersion,.metadata.creationTimestamp)' | kubectl -n vendor apply -f -`, then add
`imagePullSecrets: [{name: regcred}]` to the pod template (or patch the `default` ServiceAccount) and apply.
