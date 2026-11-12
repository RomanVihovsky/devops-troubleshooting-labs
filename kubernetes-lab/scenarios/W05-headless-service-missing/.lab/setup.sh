# W05: serviceName: web, but the only Service is the ClusterIP "web-svc" - no per-pod DNS records
kns kv
ka -f kv.yaml
r3() { [ "$(kx -n kv get sts web -o jsonpath='{.status.readyReplicas}')" = 3 ]; }
retry 180 r3 || die "web not 3/3"
