# A13 - audit log forensics: who read a Secret

**How**: the API server logs every request that matches its audit policy; here Secrets at `Metadata` (who, what,
when, from where - not the value). On `k8s-cp1`:
```
sudo jq -c 'select(.objectRef.resource=="secrets" and .objectRef.namespace=="payments"
            and (.objectRef.name=="api-key" or .verb=="list" or .verb=="watch"))
  | {t: .requestReceivedTimestamp, verb, user: .user.username, pod: .user.extra["authentication.kubernetes.io/pod-name"],
     ip: .sourceIPs, ua: .userAgent, code: .responseStatus.code}' /var/log/kubernetes/audit/audit.log
```
**Answer**: `system:serviceaccount:ci:reporter` from pod `nightly-export-...` (bound tokens carry the pod name and
UID in `user.extra`), and user `bob` (an x509 client certificate: CN=bob, O=devs). alice's reads were in
`partners-int` - a different Secret with the same name.

**Interview notes**
- Levels: `None` < `Metadata` < `Request` < `RequestResponse`. Never log Secrets above `Metadata` - the log would
  contain the values.
- Stages: `RequestReceived`, `ResponseStarted` (watch), `ResponseComplete`, `Panic`. Rules are first-match.
- Behind a load balancer `sourceIPs` shows the LB unless it forwards the client address.
- Next steps after a leak: rotate the key, check RBAC (`kubectl auth can-i --list --as=bob -n payments`), ship the
  audit log off the node (webhook backend / log agent) so an attacker can't edit it.
