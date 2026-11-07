# Solution - MTU black hole on the overlay

**Root cause**: worker2's `eth0` MTU was lowered to 1400. Both `files` tasks run on
worker1. A request via worker2 enters worker2's routing mesh and is forwarded over
the overlay (VXLAN) to worker1. Responses come back as VXLAN packets: inner
1450 bytes + 50 bytes VXLAN header = **1500-byte** frames, which worker2's 1400-byte
interface drops silently. TCP handshake, headers and small responses fit; full-size
segments never arrive and no ICMP "fragmentation needed" is generated -> the
transfer stalls (a *black hole*).

**Diagnose**
```
docker service ps app_files                          # tasks on worker1
ping -M do -s 1472 -c2 172.30.0.22   # from worker1: 100% loss
ping -M do -s 1372 -c2 172.30.0.22   # works -> path MTU 1400
ip -d link show eth0                  # on each node: worker2 says mtu 1400
tcpdump -ni eth0 udp port 4789        # on worker1: big packets go out, retransmitted forever
```

**Fix**: `ip link set eth0 mtu 1500` on worker2. If the underlay truly is smaller
(VPN, GRE, some clouds), lower the overlay instead:
`driver_opts: { com.docker.network.driver.mtu: "1350" }` on stack networks, and
recreate `ingress` with `--opt com.docker.network.driver.mtu=1350`.

**Emulation**: MTU lowered inside worker2's netns; TSO/GSO turned off on the other
nodes' `eth0` so the virtual NIC really transmits 1500-byte frames.
