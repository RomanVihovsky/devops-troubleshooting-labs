# G03: /api prefix routed to an app that serves /items; the rewrite annotation is ingress-nginx's, Traefik ignores it
kns api-gw
ka -f api.yaml
wait_rollout api-gw deploy/items
[ "$(http_out http://192.168.56.200/api/items shopfront.lab)" = 404 ] || die "/api/items does not 404"
