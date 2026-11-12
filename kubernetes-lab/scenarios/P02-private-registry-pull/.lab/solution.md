# P02 - a pull Secret in another namespace

**Root cause**: the image lives on the htpasswd-protected registry `registry.lab:5001`, and the Deployment had no
`imagePullSecrets`. The working Secret `regcred` exists, but in namespace `ci`. Pull Secrets (like every Secret a
pod uses) must be in the pod's namespace and be referenced by the pod spec or its ServiceAccount.

**Diagnosis**
```
kubectl -n vendor describe pod -l app=vendor-api | grep -A4 Events     # 401 / authorization failed
kubectl get secrets -A --field-selector type=kubernetes.io/dockerconfigjson
kubectl -n ci get secret regcred -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq '.auths | keys'
```

**Fix**: copy `regcred` into `vendor` and reference it: `imagePullSecrets: [{name: regcred}]` in the pod template, or
on the ServiceAccount (`kubectl -n vendor patch sa default -p '{"imagePullSecrets":[{"name":"regcred"}]}'`,
which then applies to every new pod of that SA).

**Interview notes**
- `kubernetes.io/dockerconfigjson` holds `auths.<registry host[:port]>`. The key must match the image's host
  exactly (port included).
- The kubelet passes the credentials to the CRI per pull. Nodes need no `docker login`, and a node that has
  the image cached may start the pod without them (`imagePullPolicy: IfNotPresent`): a classic "works on
  some nodes". The `KubeletEnsureSecretPulledImages` feature closes that gap.
- Fleet-wide registry auth: a credential provider plugin on the nodes (ECR/GCR/ACR), or a controller that
  copies a pull Secret into every namespace.
- "Use the public copy" fixes the symptom and breaks the licensing requirement. Read the constraints in the ticket.
