# Solution - choose the inventory hostname (Name tag) and the connection address (private IP) explicitly

**Root cause**: `aws_ec2` without `hostnames:` names each host after its first available default preference -
the **public DNS name** (`ec2-54-....compute.amazonaws.com`). Ansible connects to the inventory hostname unless
`ansible_host` says otherwise, so SSH tried to resolve the public name (not resolvable inside the VPC; and the
deploy must not go through public IPs anyway). `host_vars/shop-db-1.yml` didn't match either.

**Fix**
```yaml
hostnames:
  - tag:Name                       # what humans, host_vars and --limit use
compose:
  ansible_host: private_ip_address # how to connect
```

**Interview notes**
* Inventory hostname vs `ansible_host` are independent - pick both deliberately for every dynamic inventory
  (`hostnames` can also be `private-ip-address`, `instance-id`, `tag:Name=Value`, or Jinja since amazon.aws 9.2).
* Names must be unique: two instances with the same Name tag collapse into one host - add `instance-id` as a
  fallback or use `hostnames: [{name: tag:Name, prefix: ...}]`.
* Never "fix" unreachable hosts by disabling host key checking; distribute host keys (or use SSM / bastion).
