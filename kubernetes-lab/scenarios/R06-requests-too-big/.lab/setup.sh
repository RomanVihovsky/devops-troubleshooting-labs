# R06: memory requests sized for an 8 GB VM; the nodes have 4 GiB
kns analytics2
ka -f analytics.yaml
insufficient() { kx -n analytics2 get events -o jsonpath='{.items[*].message}' | grep -q 'Insufficient memory'; }
retry 60 insufficient || die "not Pending on memory"
