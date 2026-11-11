# API down since audit logging was switched on
**INC-2384** · P1 · Reporter: security engineering

Compliance wants an audit trail of who reads Secrets and ConfigMaps. I added an audit policy
(`/etc/kubernetes/audit/policy.yaml` on `k8s-cp1`) and the audit flags to the kube-apiserver manifest, mounted
the policy - and since then `kubectl` says *connection refused*. Keep auditing on: the policy, the log path
`/var/log/kubernetes/audit/audit.log` **on the node** (the log shipper reads it there) and the retention flags.

**Test**: the API answers and the kube-apiserver mirror pod is Ready; the audit flags are still set; reading a
Secret produces a fresh event in `/var/log/kubernetes/audit/audit.log` on `k8s-cp1`'s filesystem; only the 4
control-plane manifests are in `/etc/kubernetes/manifests`.
