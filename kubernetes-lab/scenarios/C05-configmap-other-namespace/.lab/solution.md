# C05 - the right ConfigMap in the wrong namespace

**Root cause**: the runbook's file has no `metadata.namespace`, so `kubectl apply` put the ConfigMap into the
namespace of the current context: `default`. Pods resolve `configMapRef` (and `secretKeyRef`, volumes) only in
**their own** namespace. The kubelet reports "not found" and retries.

**Diagnosis**
```
kubectl -n checkout describe pod -l app=checkout | grep -A2 Warning
kubectl get configmap -A --field-selector metadata.name=app-config
```

**Fix**: create it in `checkout` (`kubectl -n checkout apply -f ...`) and remove the stray copy from `default`.

**Interview notes**
- There is no cross-namespace reference for ConfigMaps/Secrets in a pod spec. Sharing needs a copy (a
  controller such as Reflector or Kyverno generate rules), or the app reads it via the API with RBAC.
- Write `namespace:` into manifests (or use Kustomize `namespace:`). Relying on the current context makes the
  same file land in different places on different laptops.
- `kubectl config set-context --current --namespace=...` explains half of the "it exists!" tickets.
