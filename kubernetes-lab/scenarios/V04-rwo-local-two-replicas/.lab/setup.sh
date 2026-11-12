kns thumbs
ka -f thumbs.yaml
pending() { [ "$(kx -n thumbs get pods -l app=thumbs --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
sleep 15
retry 60 pending || die "no Pending replica"
