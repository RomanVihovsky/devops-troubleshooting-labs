for n in $(workers); do kx cordon "$n" >/dev/null; done
kns notify
ka -f notify.yaml
pending() { [ "$(kx -n notify get pods -l app=notify --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
