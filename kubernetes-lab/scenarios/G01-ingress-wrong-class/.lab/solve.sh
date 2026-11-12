sed -i 's/ingressClassName: nginx/ingressClassName: traefik/' gallery.yaml
kx apply -f gallery.yaml >/dev/null
