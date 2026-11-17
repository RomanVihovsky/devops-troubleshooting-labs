## Hint 1
`kubectl -n scanner exec deploy/image-scanner -- cat /etc/resolv.conf` - look at `search` and `options`. How many
dots does `registry.lab` have, and what does `ndots:5` mean for it?

## Hint 2
A name with fewer than `ndots` dots is tried with every search domain **first**: 3 domains x (A + AAAA) = 6
NXDOMAIN answers before the real lookup. A trailing dot makes a name absolute (fully qualified).

## Hint 3
Either call `http://registry.lab.:5000/v2/` (note the dot after `lab`), or lower the threshold for this pod:
`spec.template.spec.dnsConfig: {options: [{name: ndots, value: "1"}]}`. Apply and watch the NXDOMAIN rate.
