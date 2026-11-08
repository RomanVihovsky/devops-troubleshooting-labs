# Every host UNREACHABLE since the switch to the EC2 inventory
**OPS-3190** · P2 · Reporter: release manager

Since the platform team replaced the CMDB export with the EC2 dynamic inventory this morning, the shop deploy
fails on every host:

```
fatal: [ec2-54-214-...eu-west-1.compute.amazonaws.com]: UNREACHABLE! => {"changed": false,
  "msg": "Failed to connect to the host via ssh: ssh: Could not resolve hostname
  ec2-54-214-....eu-west-1.compute.amazonaws.com: Name or service not known", "unreachable": true}
```

The instances are fine - `ssh ansible@10.78.0.11` from the runner works. Our hosts are known by their **Name
tag** everywhere (dashboards, `host_vars/`, runbooks). Fix the inventory so the deploy works again; host key
checking stays on.

**Test**: `ansible-inventory` lists shop-web-1, shop-web-2, shop-db-1 by Name tag with their private IPs as
`ansible_host`; site.yml applies and converges; `host_vars/shop-db-1.yml` applies (shop-db-1 is the primary);
host key checking is on.
