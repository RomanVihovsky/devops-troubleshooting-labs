# B05 - everything that differs between two namespaces

1. **Pull Secret**: `imagePullSecrets: [regcred]` - but Secrets are namespaced and `regcred` exists only in
   `web-staging`: *ImagePullBackOff ... unauthorized* (P02). Copy it (or a ServiceAccount with `imagePullSecrets`).
2. **ConfigMap**: `envFrom: web-config` - also only in staging: *CreateContainerConfigError: configmap "web-config" not
   found* (C05).
3. **Architecture**: tag `1.6` is the ARM build staging's nodes need; on amd64 nodes it dies with *exec format error*
   (P03). Use the amd64 tag `1.4` (or a multi-arch manifest list).
4. **Ingress class**: `ingressClassName: nginx` - no controller here watches it, so nothing serves `web.prod.lab`
   (Traefik answers 404 for unknown hosts) (G01). `kubectl get ingressclass` -> `traefik`.

Each fault hides the next: you only see the ConfigMap error after the pull works, the exec format error after the
config is there, and the Ingress after the pods are Ready.

**Interview notes**
- "Works in staging" checklist: namespaced dependencies (Secrets, ConfigMaps, ServiceAccounts, PVCs), node
  differences (arch, taints, labels), cluster add-ons (ingress class, storage class, CRDs), and policies.
- Kustomize overlays / Helm values per environment make these differences explicit instead of copy-paste.
