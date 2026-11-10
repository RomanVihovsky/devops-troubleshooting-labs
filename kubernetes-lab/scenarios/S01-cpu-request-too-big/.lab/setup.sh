kns render
ka -f render.yaml
pending() { [ "$(kx -n render get pods -l app=render --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
sleep 5
