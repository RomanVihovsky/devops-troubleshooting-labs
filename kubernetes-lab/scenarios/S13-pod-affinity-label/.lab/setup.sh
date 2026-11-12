# S13: required pod affinity to app=cache; the cache pods are app=redis-cache
kns sessions
ka -f sessions.yaml
wait_rollout sessions deploy/redis-cache
pending() { [ "$(kx -n sessions get pods -l app=session-api --field-selector=status.phase=Pending --no-headers | wc -l)" = 2 ]; }
retry 60 pending || die "session-api not Pending"
