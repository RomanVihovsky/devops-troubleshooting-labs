# G02: the Ingress backend uses Service port 80; the Service only has 8080
kns catalog2
ka -f catalog.yaml
wait_rollout catalog2 deploy/catalog
[ "$(http_out http://192.168.56.200/ catalog.lab)" = 404 ] || die "catalog.lab does not 404"
