# X06 - ipBlock except, and least privilege

**Root cause**: the rule allowed `192.168.56.0/24` **except** `192.168.56.16/28`, meant as "not the cluster
nodes". A /28 starting at .16 covers .16-.31, and that includes the payment API at .20 (and not all the nodes:
cp1 is .21, but w1-w3 are .31-.33, so .32 and .33 stay open). Meanwhile everything else in the /24 was open
on every port.

**Diagnosis**
```
kubectl -n payx describe networkpolicy client-egress
python3 -c 'import ipaddress as i; print(i.ip_address("192.168.56.20") in i.ip_network("192.168.56.16/28"))'   # True
```

**Fix**: allow exactly the API: `ipBlock: {cidr: 192.168.56.20/32}` + `port: 8080` (and DNS).

**Interview notes**
- `ipBlock` is for addresses **outside** the cluster. Pod IPs are matched by selectors, and with Calico,
  traffic to node IPs may hit host endpoints. CIDR arithmetic: /28 = 16 addresses aligned on 16.
- Egress to external SaaS by DNS name needs FQDN policies (Calico `domains`, Cilium `toFQDNs`) or an egress
  proxy/gateway with a fixed IP.
- Least privilege for egress: per destination **and** port. An open /24 is a pivot point.
