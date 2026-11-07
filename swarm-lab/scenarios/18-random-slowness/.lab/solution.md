# Solution - selective netem delay on overlay traffic

**Root cause**: worker1's `eth0` has a `prio` root qdisc; a `u32` filter sends only
packets with UDP destination port **4789 (VXLAN)** to band 3, where `netem` adds
400 +/- 150 ms delay and 5% loss. ICMP and the control plane use other bands, so
ping looks perfect - but every cross-node container packet leaving worker1 is
delayed, and lost packets add TCP retransmission timeouts (200 ms+, exponential).

**Diagnose** (on worker1)
```
tc -s qdisc show dev eth0      # prio 1: + netem 30: delay 400ms 150ms loss 5%, "Sent/dropped" counters
tc filter show dev eth0        # match ... dport 4789 -> flowid 1:3
```
Elsewhere: response bodies show slow requests always involve a worker1 task or redis
on/behind worker1; `tcpdump -tttt` on both ends shows the 400 ms gap.

**Fix**: `tc qdisc del dev eth0 root`

**Emulation**: this is exactly how you build your own latency/loss scenarios:
```
tc qdisc add dev eth0 root netem delay 100ms 20ms loss 1%     # everything
tc qdisc add dev eth0 root netem rate 1mbit                   # slow link
tc qdisc add dev eth0 root netem duplicate 1% reorder 25%     # weird links
```
(or `./lab inject <node> latency|loss ...`). Real-world causes: a congested or
shaped link, a bad bond member, QoS policies that classify by port.
