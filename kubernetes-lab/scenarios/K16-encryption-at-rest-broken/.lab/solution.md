# K16 - encryption at rest: the file must be mounted, the key must be 32 bytes

**Root causes** (two, one after the other):
1. `--encryption-provider-config=/etc/kubernetes/enc/enc.yaml` - but the API server runs in a container that only
   sees its hostPath mounts (`/etc/kubernetes/pki`, `/etc/ssl/certs`, ...). `/etc/kubernetes/enc` isn't one:
   *open /etc/kubernetes/enc/enc.yaml: no such file or directory*.
2. Once mounted: the `aescbc` key decodes to **31** bytes; AES needs 16, 24 or 32 (*invalid key size*).

**Fix** (on `k8s-cp1`):
```
head -c 32 /dev/urandom | base64          # a real 32-byte key into enc.yaml
# kube-apiserver.yaml: volume {name: k8s-enc, hostPath: {path: /etc/kubernetes/enc}} + volumeMount readOnly
kubectl get secrets -A -o json | kubectl replace -f -    # rewrite every Secret -> stored encrypted
```
New writes use the **first** provider; reads try them in order (so `identity: {}` last still reads old plaintext).
Existing objects stay plaintext until they're written again - hence the replace.

**Interview notes**
- Check in etcd: `etcdctl get /registry/secrets/<ns>/<name> | hexdump -C | head` - `k8s:enc:aescbc:v1:key1:`.
- `aescbc` is legacy-ish; `secretbox` or `aesgcm` (with key rotation) or a **KMS v2** plugin are preferred.
- Key rotation: add the new key first (not used), restart all API servers, move it to the top, restart, rewrite all
  Secrets, then remove the old key.
- The encryption config file holds the key: 0600, root, and back it up - without it the encrypted Secrets are gone.
