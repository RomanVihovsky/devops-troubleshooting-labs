# T16 - solution and takeaways

- `/etc/kubernetes/enc/enc.yaml`: EncryptionConfiguration, `secrets` → `aescbc` (key1, 32 random bytes,
  base64) then `identity`; `--encryption-provider-config=/etc/kubernetes/enc/enc.yaml` + a read-only
  hostPath mount; then `kubectl get secrets -A -o json | kubectl replace -f -`.
- `/etc/kubernetes/audit/policy.yaml`: `Metadata` for `secrets`, `None` for the rest;
  `--audit-policy-file`, `--audit-log-path=/var/log/kubernetes/audit/audit.log` (+ maxage/maxbackup/maxsize),
  mounts for the policy (read-only) and the log directory.
- `kubectl label ns t16 pod-security.kubernetes.io/enforce=restricted`.

**Takeaways**
- Without encryption at rest, every etcd snapshot and disk image contains all Secrets in clear text (T08).
  `aescbc`/`secretbox` with a key on the control-plane disk protects backups and stolen disks, not a
  compromised control plane; KMS v2 moves the key out. Key rotation = add key2 first, restart, re-encrypt,
  drop key1.
- Audit levels: None < Metadata < Request < RequestResponse. Never log Secret *contents* - Metadata says
  who read which Secret when (A13). Rules are first-match.
- A typo in a static pod manifest flag or mount takes the API server down: always keep a copy outside
  the manifests directory (kubelet runs *every* file in it).
- PSA replaces PodSecurityPolicy: `enforce` / `audit` / `warn` labels per namespace, profiles privileged,
  baseline, restricted. Check with `--dry-run=server` before enforcing (A04).
