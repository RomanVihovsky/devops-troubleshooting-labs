kns analytics
ka -f analytics.yaml
restarted() { [ "$(restarts analytics app=analytics)" -ge 1 ]; }
retry 180 restarted || die "no restarts"
