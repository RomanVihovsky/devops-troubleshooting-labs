## Hint 1
`kubectl get ingressclass` and `kubectl -n gallery get ingress gallery` (CLASS, ADDRESS). Who should serve it?

## Hint 2
An ingress controller only acts on Ingresses of **its** class. This cluster runs Traefik (class `traefik`, the
default); the manifest names `nginx`, which nothing here implements.

## Hint 3
`ingressClassName: traefik` (or remove the field: `traefik` is the default class), apply.
