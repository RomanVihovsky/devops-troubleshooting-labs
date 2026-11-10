for n in $(workers); do kx taint node "$n" dedicated=batch:NoSchedule --overwrite >/dev/null; done
kns etl
ka -f etl.yaml
pending() { [ "$(kx -n etl get pods -l app=etl --field-selector=status.phase=Pending --no-headers | wc -l)" -ge 1 ]; }
retry 60 pending || die "no Pending pods"
sleep 5
