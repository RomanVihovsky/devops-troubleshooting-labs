## Hint 1
Peel it layer by layer: `kubectl -n web-prod get pods`, `kubectl -n web-prod describe pod <pod>` (the events), fix,
look again. Then the Ingress: `kubectl get ingressclass`, `kubectl -n web-prod describe ingress web`.

## Hint 2
Four differences between the namespaces: the pull Secret (namespaced - pods can only use Secrets of their own
namespace), the image's **CPU architecture** (`exec format error` means the image is for another platform),
`envFrom` a ConfigMap that only exists in staging, and an `ingressClassName` no controller here serves.

## Hint 3
Copy `regcred` and `web-config` into `web-prod` (strip namespace/uid/resourceVersion), use the amd64 tag `1.4`, set
`ingressClassName: traefik`. Apply, wait for the rollout, then `curl -H 'Host: web.prod.lab' http://192.168.56.200/`.
