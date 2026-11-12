## Hint 1
Read the whole error: it lists the label and annotations Helm expects on an object before it will adopt it.

## Hint 2
Helm adopts an existing object only if it carries `app.kubernetes.io/managed-by: Helm` and the annotations
`meta.helm.sh/release-name` / `meta.helm.sh/release-namespace` naming this release.

## Hint 3
`kubectl -n importx label svc web app.kubernetes.io/managed-by=Helm` and `kubectl -n importx annotate svc web
meta.helm.sh/release-name=web meta.helm.sh/release-namespace=importx`, then the `helm install` again.
