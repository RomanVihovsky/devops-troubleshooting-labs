kns quotes
ka -f quotes.yaml
running() { [ "$(kx -n quotes get pods -l app=quotes --field-selector=status.phase=Running --no-headers | wc -l)" = 2 ]; }
retry 120 running || die "pods not Running"
sleep 10
! has_endpoints quotes quotes || die "quotes became Ready"
