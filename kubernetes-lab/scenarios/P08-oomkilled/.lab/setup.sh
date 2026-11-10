kns search-cache
ka -f cache.yaml
oom() { kx -n search-cache get pods -o json | jq -e '[.items[].status.containerStatuses[]? | .lastState.terminated.reason // ""] | any(. == "OOMKilled")' >/dev/null; }
retry 180 oom || die "no OOMKilled"
