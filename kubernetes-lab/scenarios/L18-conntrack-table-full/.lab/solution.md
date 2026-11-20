# L18 - conntrack table full on one node

**Root cause**: `/etc/sysctl.d/80-conntrack.conf` on w3 sets `net.netfilter.nf_conntrack_max` to a few thousand
above the node's normal number of tracked connections. Every connection through the node needs an entry - pod ->
Service traffic is DNATed by kube-proxy's rules - and closed TCP connections stay in the table (TIME_WAIT) for 2
minutes. A load test with short connections fills it within seconds; then the kernel drops the first packet (SYN) of
every new connection: *nf_conntrack: table full, dropping packet*, seen by clients as connect timeouts. Other nodes
keep kube-proxy's default (131072).

**Diagnosis**
```
./lab node w3
  dmesg -T | grep -i conntrack                 # table full, dropping packet
  cat /proc/sys/net/netfilter/nf_conntrack_{count,max}
  conntrack -S | grep -o 'drop=[0-9]*'         # per-CPU drop counters (conntrack-tools)
  grep -r conntrack /etc/sysctl.d/
```

**Fix**: delete the file (or set >= 131072) **and** raise the live value: `sysctl -w net.netfilter.nf_conntrack_max=131072`.

**Interview notes**
- kube-proxy sets `nf_conntrack_max` = max(`conntrack.maxPerCore` x cores, `conntrack.min`) at start-up - a later
  sysctl or a restart order where the sysctl runs after kube-proxy wins.
- Memory: about 300 bytes per entry - 131072 entries are ~40 MB, not worth starving a node over.
- Related: `nf_conntrack_tcp_timeout_time_wait`, the UDP DNS race (insert_failed) behind 5 s DNS delays, and
  NodeLocal DNSCache using NOTRACK.
