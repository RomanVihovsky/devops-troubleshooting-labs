# A12 - resourceNames typo

**Root cause**: the Role allows `get` on `secrets` with `resourceNames: [db-cred]` - the Secret is `db-creds`.
The Job's API request is denied. The app pod is unaffected: mounting a Secret is the **kubelet's** request
(node authorizer: a node may read the Secrets its pods reference), not the pod's ServiceAccount.

**Diagnosis**
```
kubectl auth can-i get secret/db-creds -n payroll --as=system:serviceaccount:payroll:syncer   # no
kubectl -n payroll get role secret-reader -o yaml
kubectl -n payroll logs job/secret-sync
```

**Fix**: `resourceNames: [db-creds]`; delete and re-create the Job.

**Interview notes**
- `resourceNames` narrows `get`/`update`/`patch`/`delete` to named objects; it can't narrow `list`/`watch`/
  `create` (no name in the request) - granting `list` would expose every Secret.
- Secret volumes and env vars are fetched by the kubelet (node authorizer + NodeRestriction), API reads by
  the pod's ServiceAccount: two different identities.
- Jobs are immutable once done: a fix needs a new Job (or `kubectl create job --from=cronjob/...`).
