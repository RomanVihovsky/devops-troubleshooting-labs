kns ml
ka -f ml-api.yaml
pending() { [ "$(kx -n ml get pods -l app=ml-api --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
