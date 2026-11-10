kns profile
ka -f profile.yaml
restarted() { [ "$(restarts profile app=profile)" -ge 1 ]; }
retry 180 restarted || die "no liveness restarts"
