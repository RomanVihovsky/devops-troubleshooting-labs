# A07 - a grant to everyone

**Root cause**: ClusterRoleBinding `secret-reader` gave ClusterRole `secret-reader` (get/list/watch secrets) to the
group **`system:authenticated`**. Every authenticated identity is in it: every user and every ServiceAccount of
every pod. Any compromised pod could read every Secret in the cluster.

**Diagnosis**
```
kubectl auth can-i list secrets -A --as bob                                   # yes
kubectl auth can-i list secrets -A --as system:serviceaccount:default:default # yes
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.subjects[]?.name == "system:authenticated") | .metadata.name + " -> " + .roleRef.name'
kubectl auth can-i --list --as bob | grep secrets
```

**Fix**: bind the ClusterRole to the one subject that needs it: ServiceAccount `backup/backup-agent`.

**Interview notes**
- Built-in groups: `system:authenticated`, `system:unauthenticated`, `system:serviceaccounts`,
  `system:serviceaccounts:<ns>`, `system:masters` (bypasses RBAC: never hand it out).
- Auditing RBAC: `kubectl auth can-i --list --as`, `kubectl-who-can list secrets`, rbac-tool. List access to
  Secrets = read access (list returns the data).
- Least privilege for backup tools: a dedicated SA; ideally namespaced RoleBindings or encryption so the tool
  stores ciphertext only.
