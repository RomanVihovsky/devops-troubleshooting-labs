kns store
ka -f store.yaml
wait_rollout store deploy/store
[ "$(http_out http://192.168.56.200/ www.store.lab)" = 404 ] || die "www.store.lab does not 404"
