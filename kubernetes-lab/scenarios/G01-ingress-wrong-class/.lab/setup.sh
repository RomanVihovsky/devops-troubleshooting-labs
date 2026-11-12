# G01: ingressClassName nginx - no controller in this cluster serves it
kns gallery
ka -f gallery.yaml
wait_rollout gallery deploy/gallery
[ "$(http_out http://192.168.56.200/ gallery.lab)" = 404 ] || die "gallery.lab does not 404"
