# P15: a 300 MiB disk cache in the container's writable layer, ephemeral-storage limit 100Mi -> evictions
kns thumbs
ka -f thumbs.yaml
evicted() { kx -n thumbs get pods -o jsonpath='{.items[*].status.reason}' | grep -q Evicted; }
retry 240 evicted || die "no eviction"
