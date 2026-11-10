kx label node k8s-w2 disk=ssd --overwrite >/dev/null
kns indexer
ka -f indexer.yaml
pending() { [ "$(kx -n indexer get pods -l app=indexer --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
sleep 5
