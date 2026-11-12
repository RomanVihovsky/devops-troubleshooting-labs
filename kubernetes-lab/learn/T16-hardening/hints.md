## Hint 1
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources: [secrets]
    providers:
      - aescbc: {keys: [{name: key1, secret: <head -c 32 /dev/urandom | base64>}]}
      - identity: {}
```
The first provider encrypts, all of them may decrypt. Re-encrypt: `kubectl get secrets -A -o json |
kubectl replace -f -`.

## Hint 2
In `kube-apiserver.yaml`: the flags under `command`, a `volumeMounts` entry per directory (`/etc/kubernetes/enc`,
`/etc/kubernetes/audit` read-only, `/var/log/kubernetes/audit` writable) and matching `hostPath` `volumes`.
A missing mount = the API server can't start: `crictl ps -a | grep apiserver`, `crictl logs <id>`.

## Hint 3
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages: [RequestReceived]
rules:
  - {level: Metadata, resources: [{group: "", resources: [secrets]}]}
  - {level: None}
```
PSA: `kubectl label ns t16 pod-security.kubernetes.io/enforce=restricted`; test with
`kubectl -n t16 run p --image=docker.io/library/busybox:1.37 --privileged --dry-run=server`.
