## Hint 1
Find the pattern: which tasks are slow? Use the hostname in the response body and
`docker service ps app_web app_redis`. Is one node always involved?
## Hint 2
ICMP is fine, but is *all* traffic treated the same? Compare `ping` with overlay
traffic: `tcpdump -ni eth0 udp port 4789` timestamps on both ends, or `mtr`.
Look at the queueing disciplines on each node's NIC: `tc -s qdisc show dev eth0`.
## Hint 3
A `prio` qdisc with a `netem` child and a `tc filter` can delay only some packets
(here: only one UDP port). `tc filter show dev eth0`. Remove the root qdisc.
