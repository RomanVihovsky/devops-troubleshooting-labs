# swarm-lab

A Docker Swarm that breaks on purpose. 20 classic DevOps incidents (scheduling,
images, secrets, DNS, cgroups, filesystems, signals, firewalls, MTU, tc/netem,
routing, Raft quorum) on a 3-node swarm that runs entirely inside Docker on your
Linux box. You get a ticket with symptoms, a root shell on every "VM", and a
`verify` command that tells you when it's really fixed.

```
 host ── docker bridge "swarmlab" 172.30.0.0/24 ───────────────────────────────
           │ lab-manager1 .11 │ lab-worker1 .21 │ lab-worker2 .22 │ registry .5 │ legacy-api .50
           └─ each node = privileged Docker-in-Docker "VM": own dockerd, iptables, tc, routes
```

* Design, scenario catalog, verification approach: **[PLAN.md](PLAN.md)**
* How the network/infra faults are emulated (+ build your own): **[docs/FAULT-INJECTION.md](docs/FAULT-INJECTION.md)**

## Requirements

* Linux with Docker Engine (tested: 29.x, cgroup v2), your user in the `docker` group
* ~2 GB disk, ~2 GB RAM, free subnet `172.30.0.0/24`
* Internet only for the first `./lab up` (builds the node image, pulls 5 base images).
  No `docker compose` plugin needed - the lab uses the one inside its node image.

Nothing is changed on the host besides containers, one bridge network, volumes
and two images (`swarmlab/node:1`, `swarmlab/webapp:1.0`).

## Quick start

```bash
./lab up                 # ~1 min first time: build + start 3 nodes, init swarm, seed registry
./lab list               # the 20 incidents
./lab start 01           # break things, print the ticket
./lab sh manager1        # root shell on the manager "VM" (also: worker1, worker2)
./lab verify             # PASS / FAIL against the ticket's "Done when"
```

From the host the app is at `http://172.30.0.11:8080` (also `.21`, `.22` - the routing mesh).

## How to play

1. `./lab start <id>` (or `./lab start random`) - read the ticket. It only describes symptoms.
2. Investigate like on real servers: `./lab sh <node>`. The swarm CLI works on managers
   (`docker node ls`, `docker service ps --no-trunc app_web`, `docker service logs ...`);
   on workers you have the local `docker`, plus `ip`, `ss`, `tcpdump`, `iptables-save`,
   `tc`, `nsenter`, `strace`, `lsof`, `dig`, `mtr`, `df`, `/proc`, `/sys/fs/cgroup`...
   dockerd's own log of a node: `docker logs lab-worker1` (on the host).
3. Fix it - the stack files are in `workspace/` (= `/lab/workspace` on every node).
   Edit, then `./lab deploy` (or `docker stack deploy -c /lab/workspace/stack.yml app`
   on manager1). Some fixes belong on a node, not in the stack.
4. `./lab verify`. Stuck? `./lab hint` (progressive, run it again for the next one), then `./lab solution`.
   `./lab solve` applies the reference fix if you just want to see it work.
5. `./lab start <next>` resets everything automatically.

**Rules of the game**: don't read `scenarios/*/.lab/` (spoilers: setup, verify, solution)
and don't use `./lab reset` as a fix. Some checks guard against shortcuts
(e.g. "don't reboot the node", "the cache size must stay").

## Incidents

| # | Ticket | | # | Ticket |
|---|---|---|---|---|
| 01 | Shop database never starts | | 11 | web never becomes healthy after "right-sizing" |
| 02 | Reports service never gets a container | | 12 | Disk full, but there is nothing on the disk |
| 03 | report-api 1.4 runs only one replica | | 13 | "No space left on device" with 99% free |
| 04 | Global agent missing on one node | | 14 | Every deploy takes minutes |
| 05 | Web replicas keep restarting | | 15 | Half of the requests hang |
| 06 | Crash loop after moving the password to a secret | | 16 | worker1 is Down, but the VM is fine |
| 07 | Homepage returns 502 after network segmentation | | 17 | Downloads hang through one load-balancer node |
| 08 | Config change cannot be deployed | | 18 | p90 latency terrible, network looks perfect |
| 09 | 502/504 from the proxy after every redeploy | | 19 | Billing can't reach the legacy API - from swarm only |
| 10 | web dies with exit code 137 | | 20 | Two managers lost - the swarm is headless |

01-09 swarm mechanics · 10-14 Linux resources & processes · 15-19 network
infrastructure · 20 disaster recovery (adds manager2/manager3 automatically).

## Chaos mode

Layer your own faults on top of any scenario (or a healthy stack):

```bash
./lab inject worker1 latency 300 50      # tc netem 300ms ±50ms
./lab inject worker2 loss 20             # 20% packet loss
./lab inject worker2 block udp 4789      # kill the overlay data plane
./lab inject manager1 block tcp 2377     # workers lose the control plane -> Down
./lab inject worker2 mtu 1400
./lab inject worker1 partition           # isolate from all other nodes
./lab inject worker2 dns                 # broken resolver on the node
./lab inject worker1 freeze              # docker pause the whole VM
./lab clear                              # undo all of the above
```

## Cheat sheet

```bash
# swarm (manager)
docker node ls; docker node inspect --pretty worker1
docker service ls; docker service ps --no-trunc app_web; docker service logs -f app_web
docker service inspect --pretty app_web; docker stack ps app
docker network inspect -v app_default          # VIPs, tasks, peers
# container on a node
docker ps; docker inspect -f '{{.State.Pid}} {{.State.OOMKilled}} {{json .State.Health}}' <cid>
nsenter -n -t <pid> ip route | ss -tnp | ip route get 1.2.3.4
# network
tcpdump -ni eth0 'udp port 4789 or tcp port 2377 or port 7946'
iptables-save; tc -s qdisc show dev eth0; ip -d link; ping -M do -s 1472 <ip>; nc -zv <ip> <port>
# resources
docker stats --no-stream; dmesg -T | tail; df -h; df -i; lsof +L1; cat /sys/fs/cgroup/.../cpu.stat
```

## Maintenance

```bash
./lab status             # nodes + services
./lab reset --hard       # also restarts every node (fresh network namespaces)
./lab selftest all       # prove every scenario breaks and is fixable (~25 min)
./lab destroy            # remove everything the lab created
docker rmi swarmlab/node:1 swarmlab/webapp:1.0   # optional, after destroy
```
