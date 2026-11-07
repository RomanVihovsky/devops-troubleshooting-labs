## Hint 1
A node is "Down" when the managers stop receiving its heartbeats. What does
worker1 say about its swarm connection? `docker info` on worker1, and the
daemon log: `docker logs lab-worker1` **from the host** (dockerd's output).
## Hint 2
Test each swarm port from worker1 to manager1: `nc -zv -w2 manager1 2377`,
`nc -zv -w2 manager1 7946`. ICMP working proves very little. Is the SYN leaving?
`tcpdump -ni eth0 tcp port 2377`
## Hint 3
If the packet never shows up on eth0, it's dropped *locally*, on the way out.
`iptables -L` shows only the **filter** table. Check every table: `iptables-save`
(look at `*raw`, `*mangle`, `*nat`).
