## Hint 1
Who answers external names for pods? `kubectl -n kube-system get configmap coredns -o yaml` - the `forward`
line.

## Hint 2
From a node: `dig @<that IP> pkgs.k8s.io` (or `nslookup pkgs.k8s.io <IP>`). And what does the node itself use?
`resolvectl status`.

## Hint 3
`forward . /etc/resolv.conf` (or the real upstream), CoreDNS reloads the Corefile by itself within ~30 s.
