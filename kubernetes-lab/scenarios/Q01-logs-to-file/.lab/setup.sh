# Q01: the app logs only to a file inside the container
kns billing2
ka -f invoicer.yaml
wait_rollout billing2 deploy/invoicer
http_code billing2 http://invoicer.billing2.svc:8080/items >/dev/null || true   # one request for the (empty) logs
[ -z "$(kx -n billing2 logs deploy/invoicer 2>/dev/null | grep 'GET /items')" ] || die "the request shows up in kubectl logs"
