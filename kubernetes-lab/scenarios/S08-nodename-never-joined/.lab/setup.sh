kns legacy
ka -f legacy-sync.yaml
pending() { [ "$(kx -n legacy get pods -l app=legacy-sync --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
