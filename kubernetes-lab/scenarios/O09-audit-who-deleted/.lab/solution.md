# O09 - audit log forensics: who deleted an object

**How**: on `k8s-cp1`,
```
sudo jq -c 'select(.verb=="delete" and .objectRef.resource=="configmaps" and .objectRef.namespace=="checkout")
  | {t: .requestReceivedTimestamp, user: .user.username, name: .objectRef.name, ua: .userAgent, code: .responseStatus.code}' \
  /var/log/kubernetes/audit/audit.log
```
Three deletes show up: `dave` -> feature-flags **403** (no RBAC - not him), `bob` -> `old-banner` (a different object),
and `carol` -> feature-flags **200** with user agent `cleanup-cron/1.2 (python-requests)` - a script running with
carol's credentials, not an interactive kubectl.

**Restore**: `kubectl apply -f feature-flags.yaml` (and make the ConfigMap part of something reconciled - GitOps -
so a delete heals itself).

**Interview notes**
- `kubectl get events` won't help: there's no event for API deletes, and events expire after an hour (Q04).
- The audit log is the only record of *who*; `metadata.managedFields` shows who last *changed* a live object.
- Correlate with `sourceIPs` and `user.extra` (bound ServiceAccount tokens name the pod), and with the `auditID`
  the API server returns in the `Audit-Id` response header.
- Prevent repeats: RBAC least privilege (no `delete` for humans in prod), admission policies, and audit logs
  shipped off the node.
