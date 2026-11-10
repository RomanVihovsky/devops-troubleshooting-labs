kns gateway
ka -f gateway.yaml
pending() { [ "$(kx -n gateway get pods -l app=gateway --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
sleep 5
