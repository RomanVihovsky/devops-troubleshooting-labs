# Solution - control-plane port 2377 blocked in the raw table

**Root cause**: on worker1, `iptables -t raw -A OUTPUT -d 172.30.0.11 -p tcp --dport 2377 -j DROP`.
Workers keep a gRPC session to a manager on TCP 2377 for heartbeats and task
assignments. With it blocked, the manager marks worker1 `Down` after the
heartbeat timeout. Containers keep running (the data plane on 4789 still works),
but the orchestrator cannot see or manage them.
The rule hides in the `raw` table, which `iptables -L` does not show.

**Diagnose** (on worker1)
```
docker info | grep -A5 Swarm
nc -zv -w2 172.30.0.11 2377            # timeout (ping works!)
tcpdump -ni eth0 tcp port 2377         # nothing leaves the box
iptables-save | grep 2377              # -t raw -A OUTPUT ... -j DROP
```
And from the host: `docker logs lab-worker1 | tail` (dockerd: "heartbeat ... timeout" / "dial tcp ... 2377").

**Fix**
```
iptables -t raw -D OUTPUT -d 172.30.0.11 -p tcp --dport 2377 -j DROP
```
The worker reconnects on its own within seconds.

**Real-world notes**: also check `nft list ruleset` (nftables), cloud security
groups, host firewalls (firewalld/ufw), and clock skew (TLS cert validation of the
mTLS swarm certs fails if clocks drift too far).
