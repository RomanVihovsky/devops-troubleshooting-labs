# Solution - dead first nameserver = 5 s resolver timeout

**Root cause**: `/etc/resolv.conf` lists a decommissioned server (10.77.0.54) **first**. It
silently drops queries, so the glibc resolver waits its default `timeout:5` before trying
the second server. Every lookup (A and AAAA, in parallel) costs ~5 s; IP-based calls skip DNS.

**Diagnose**
```
curl -o /dev/null -s -w 'dns:%{time_namelookup} total:%{time_total}\n' http://api.internal:8080/
cat /etc/resolv.conf
dig @10.77.0.54 api.internal +time=2 +tries=1     # timeout
dig @10.77.0.53 api.internal                      # instant
sudo tcpdump -ni eth0 port 53                      # queries to .54, no answers
strace -f -e trace=sendto,poll,connect curl -s http://api.internal:8080/ >/dev/null
```

**Fix**: delete the dead `nameserver` line (and fix whatever generates the file:
netplan/NetworkManager/systemd-resolved/DHCP).

**Interview notes**: "exactly 5 s" (or 5, 10, 15...) screams resolver timeout. Related:
`options timeout:1 attempts:2 rotate`, IPv6 AAAA lookups timing out, `single-request` for
broken firewalls that drop the parallel AAAA query, search domains + `ndots:5` in
Kubernetes causing several failed lookups per call, missing reverse DNS slowing down sshd
(`UseDNS no`).
