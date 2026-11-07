# Solution - nsswitch.conf and a stale /etc/hosts entry

**Root cause**: two layers.
1. `/etc/hosts` has a stale line `10.77.0.99 api.internal` (old VM). `files` is consulted
   first, so apps connect to a dead IP -> timeouts.
2. `/etc/nsswitch.conf` says `hosts: files myhostname` - **dns is missing**, so even without
   the stale entry the libc resolver never asks the DNS server.
`dig`/`nslookup`/`host` bypass both (they query DNS directly) - that's why "DNS is fine".

**Diagnose**
```
dig +short api.internal          # 10.77.0.20  (DNS server is fine)
getent hosts api.internal        # 10.77.0.99  (what apps get)
grep ^hosts: /etc/nsswitch.conf
grep api.internal /etc/hosts
```

**Fix**: `hosts: files dns myhostname` in `/etc/nsswitch.conf`, delete the stale line from
`/etc/hosts`.

**Interview notes**: "dig works but the app doesn't" -> think nsswitch, `/etc/hosts`,
`systemd-resolved` (`resolvectl query`), application/JVM DNS caches, IPv6 (AAAA tried first),
search domains / `ndots` (Kubernetes!). Use `getent` to test what apps actually see.
