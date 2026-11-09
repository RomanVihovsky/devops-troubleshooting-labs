# T16 · Hardening: encryption at rest, an audit policy, Pod Security Admission
**Learn** · three API-server features every security review asks for · ~60 min

Work on k8s-cp1 (`./lab node cp1`, `sudo -i`). Every change to the kube-apiserver manifest restarts it:
keep a copy **outside** `/etc/kubernetes/manifests` and watch `crictl ps` / `kubectl get --raw /readyz`.

1. **Encryption at rest**: right now `etcdctl get /registry/secrets/t16/legacy` shows the Secret in plain
   text. Write an EncryptionConfiguration (`/etc/kubernetes/enc/enc.yaml`, provider `aescbc` or
   `secretbox` with a fresh 32-byte key, `identity` last), add `--encryption-provider-config`, mount it into
   the API server. Then **re-encrypt the existing Secrets** - new writes alone don't touch old data.
2. **Audit**: a policy (`/etc/kubernetes/audit/policy.yaml`) that records every access to **Secrets at
   level Metadata** (who, what, when - never the content), to `/var/log/kubernetes/audit/audit.log`
   (`--audit-policy-file`, `--audit-log-path`, mounts for both).
3. **Pod Security Admission**: namespace `t16` enforces the **restricted** profile.

**Test**: `t16/legacy` and new Secrets are stored encrypted in etcd (`k8s:enc:` prefix); reading a Secret
produces a Metadata-level audit event; a privileged pod is rejected in `t16`; the API server is healthy.
