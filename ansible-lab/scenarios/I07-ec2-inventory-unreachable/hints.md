## Hint 1
`ansible-inventory --graph` - what are the host names? Without `hostnames:` the plugin uses the first of its
default preferences that an instance has: the **public DNS name**. Inside the VPC (and in this lab) those names
don't resolve, and nothing connects to the public IP anyway.

## Hint 2
Two separate decisions: the *inventory hostname* (what you see in output, what `host_vars/` and `--limit` use) and
*how to connect* (`ansible_host`). `hostnames:` sets the first; `compose:` can set the second from any hostvar
(`ansible-inventory --host <name>` lists them).

## Hint 3
```yaml
hostnames:
  - tag:Name
compose:
  ansible_host: private_ip_address
```
Known hosts are already trusted by IP. `StrictHostKeyChecking=no` or `host_key_checking = False` is not a fix.
