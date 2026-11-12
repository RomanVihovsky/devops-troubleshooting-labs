## Hint 1
`kubectl -n payx describe networkpolicy client-egress` - which addresses does the `ipBlock` allow, and which does
its `except` remove?

## Hint 2
`except` carves CIDRs **out** of the allowed block. 192.168.56.16/28 is .16 - .31 - it includes the payment API.
And as written, the rest of 192.168.56.0/24 is open on every port - more than security wants.

## Hint 3
Replace the rule with `to: [{ipBlock: {cidr: 192.168.56.20/32}}]`, `ports: [{protocol: TCP, port: 8080}]` (keep
the DNS rule), apply.
