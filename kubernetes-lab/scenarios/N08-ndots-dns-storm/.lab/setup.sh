# N08: registry.lab has 1 dot < ndots 5: every call first tries the 3 search domains (A + AAAA = 6 NXDOMAIN)
kns scanner
ka -f image-scanner.yaml
wait_rollout scanner deploy/image-scanner
