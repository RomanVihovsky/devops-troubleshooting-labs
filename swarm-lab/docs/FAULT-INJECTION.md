# How network & infrastructure problems are emulated

The trick that makes all of this safe: every swarm node is a **privileged
Docker-in-Docker container**. It has its *own* network namespace (interfaces,
routes, iptables, qdiscs), its *own* dockerd, filesystem and cgroup subtree.
Anything you break inside `lab-worker2` stays inside `lab-worker2` - your host's
networking is never touched, and `./lab reset --hard` (restart = new netns)
undoes even what you forgot.

```
./lab sh worker2          # root shell "on the VM"
docker exec lab-worker2 <cmd>   # one-off from the host
```

Quick chaos without writing anything: `./lab inject <node> <fault> ...`, undo with
`./lab clear` (see `./lab help`).

---

## 1. Network faults

### Latency, jitter, loss, bandwidth - `tc netem`
```bash
tc qdisc add dev eth0 root netem delay 200ms 50ms           # 200 ms +/- 50 ms
tc qdisc change dev eth0 root netem delay 200ms loss 5%     # + 5% loss
tc qdisc change dev eth0 root netem loss 30% 25%            # bursty loss (correlation)
tc qdisc change dev eth0 root netem duplicate 1% reorder 25% 50% corrupt 0.1%
tc qdisc add dev eth0 root tbf rate 1mbit burst 32kbit latency 400ms   # slow link
tc -s qdisc show dev eth0                                    # inspect + counters
tc qdisc del dev eth0 root                                   # undo
```
netem works on **egress**. For ingress shaping redirect to an `ifb` device
(`ip link add ifb0 type ifb; tc qdisc add dev eth0 ingress; tc filter add dev eth0
parent ffff: matchall action mirred egress redirect dev ifb0`).

### Selective impairment (only some traffic) - `prio` + `u32` filter
Makes the classic "ping is fine but the app is slow" puzzle:
```bash
tc qdisc add dev eth0 root handle 1: prio
tc qdisc add dev eth0 parent 1:3 handle 30: netem delay 400ms loss 5%
tc filter add dev eth0 parent 1:0 protocol ip prio 3 u32 match ip dport 4789 0xffff flowid 1:3
#         only VXLAN (overlay) packets go to band 3 -> delayed; ICMP/2377/7946 unaffected
tc filter show dev eth0
```
Match other things: `match ip dst 172.30.0.11/32`, `match ip protocol 17 0xff` (UDP), `match ip sport 6379 0xffff`.

### Blocking ports - `iptables` (filter, raw, custom chains)
Swarm needs between nodes: **TCP 2377** (control plane), **TCP+UDP 7946**
(gossip), **UDP 4789** (VXLAN data plane), **IP proto 50** (ESP, encrypted overlays).
```bash
iptables -I INPUT -p udp --dport 4789 -j DROP                 # data plane: nodes Ready, traffic dies
iptables -I OUTPUT -d 172.30.0.11 -p tcp --dport 2377 -j DROP # control plane: node goes Down
iptables -t raw -I OUTPUT -p tcp --dport 2377 -j DROP          # same, invisible to `iptables -L`
iptables -N HARDENING; iptables -A HARDENING ... ; iptables -I INPUT -j HARDENING   # hide in a chain
iptables -I INPUT -p tcp --dport 7946 -j REJECT --reject-with tcp-reset   # fast failure vs DROP=timeout
iptables-save                                                   # ALWAYS look at all tables
```
DROP = timeouts/hangs, REJECT = immediate "connection refused" - very different symptoms.

### Network partition (split brain)
```bash
iptables -I INPUT  -m iprange --src-range 172.30.0.2-172.30.0.254 -j DROP
iptables -I OUTPUT -m iprange --dst-range 172.30.0.2-172.30.0.254 -j DROP
```
Partition one of 3 managers: cluster survives. Partition 2 of 3: quorum lost.

### MTU / black holes
```bash
ip link set eth0 mtu 1400               # on the receiving node
ping -M do -s 1472 <ip>                 # probe: 1472 + 28 = 1500 bytes, DF set
```
Overlay (VXLAN) adds 50 bytes, so the default overlay MTU is 1450 to fit a 1500
underlay. If the underlay is smaller and ICMP "fragmentation needed" never comes
back, big TCP segments vanish: handshakes and headers work, bodies hang.
**Emulation caveat:** virtual NICs use TSO/GSO, so a "1500-byte" packet travels as a
64 KB super-packet and skips MTU checks. Turn offloads off on the senders to make the
black hole real: `ethtool -K eth0 tso off gso off tx-udp_tnl-segmentation off`.

### DNS problems
```bash
cp /etc/resolv.conf /etc/resolv.conf.bak; echo 'nameserver 192.0.2.53' > /etc/resolv.conf
#   node's dockerd can no longer resolve "registry" -> image pulls fail on that node
```
Inside swarm, containers use the embedded resolver `127.0.0.11`: service names
resolve only on shared networks; `tasks.<svc>` returns task IPs; `dnsrr` services
have no VIP. Clients that cache DNS forever (nginx `upstream`, JVM) break on redeploy.

### Routing problems
```bash
ip route add blackhole 172.30.0.50/32   # silently drop a destination
ip route add 172.30.0.50/32 via 172.30.0.99   # route to a non-existent gateway
```
Overlapping subnets are the realistic version: an overlay (or `docker_gwbridge`)
whose subnet contains an external address shadows it inside containers.
Debug from the container's netns: `nsenter -n -t $(docker inspect -f '{{.State.Pid}}' <cid>) ip route get <ip>`.

---

## 2. Node / VM faults

| Fault | Emulate (on the host) | Swarm sees |
|---|---|---|
| hung VM | `docker pause lab-worker1` (`unpause`) | node Down after ~15 s, tasks rescheduled |
| crashed VM | `docker kill lab-worker1` (`start`) | node Down, comes back Ready on start |
| dockerd crash | `docker exec lab-worker1 kill -9 $(pidof dockerd)` | same as crash (dockerd is the node's main process) |
| disk loss | `docker compose rm -sfv worker1` | node Down forever; must `docker node rm` |
| config drift | edit `/etc/docker/daemon.json` + `kill -HUP $(pidof dockerd)` | only that node misbehaves |
| maintenance | `docker node update --availability drain worker1` | tasks move away |
| quorum loss | lose 2 of 3 managers | "swarm does not have a leader" |

Not emulated: **clock skew** - time is not namespaced in Linux containers, so changing
the date inside a node would change your host's clock. Use `libfaketime` inside a
container instead if you want to experiment.

---

## 3. Container / resource faults (cgroups, filesystems, processes)

```yaml
deploy:
  resources:
    limits:   { memory: 64M, cpus: "0.05", pids: 50 }   # OOM kill, CPU throttling, fork failures
    reservations: { memory: 48G }                         # unschedulable
ulimits: { nofile: { soft: 64, hard: 64 } }             # "Too many open files"
stop_grace_period: 30s                                    # slow stops when PID 1 ignores SIGTERM
volumes:
  small:
    driver_opts: { type: tmpfs, device: tmpfs, o: "size=16m,nr_inodes=500" }  # disk full / inode full
```
Observe from the node: `docker stats`, `docker inspect -f '{{.State.OOMKilled}}'`,
`dmesg -T`, `cat /sys/fs/cgroup/<...>/cpu.stat memory.events`, `/proc/<pid>/fd`,
`/proc/<pid>/limits`, `/proc/<pid>/status` (SigCgt = handled signals).

---

## 4. Build your own scenario

1. Freestyle: `./lab start 15`, then `./lab inject worker1 latency 300 50` on top. Debug. `./lab clear`.
2. Persistent: copy a scenario directory and edit:
   ```
   scenarios/21-my-incident/
     ticket.md            "# Title" on line 1, then symptoms only
     hints.md             "## Hint 1", "## Hint 2", ...
     files/stack.yml      deployed as stack "app" (+ any config/secret files)
     .lab/setup.sh        deploy_stack; retry 60 svc_converged app_web; inject worker2 '<do>' '<undo>'
     .lab/verify.sh       check / check_eventually ...; verdict
     .lab/solve.sh        reference fix
     .lab/solution.md
   ```
   Helpers (see `lib/common.sh`): `dk` (docker on manager1), `dkn <node>`, `nsh <node> '<sh>'`,
   `inject`, `retry`, `svc_converged`, `svc_stable`, `svc_nodes`, `task_container`,
   `all_nodes_http`, `ws_sed`.
3. Prove it: `./lab selftest 21` (must FAIL before, PASS after the reference fix).

---

## 5. Spoiler: what each built-in scenario injects

<details>
<summary>Open only after solving (or giving up)</summary>

| # | Emulation |
|---|---|
| 01 | node label `disktype=ssd` vs constraint `node.labels.disk == ssd` |
| 02 | `reservations.memory: 48G` > node RAM |
| 03 | image tagged only on manager1 (`docker tag`), no registry |
| 04 | `insecure-registries: []` in worker2 daemon.json + SIGHUP, image removed |
| 05 | healthcheck runs `curl`, image has none |
| 06 | short-syntax secret mounted at `/run/secrets/redis_pw`, app reads `redis_password` |
| 07 | web on `frontend` only, redis on `backend` only |
| 08 | swarm configs are immutable |
| 09 | `endpoint_mode: dnsrr` + nginx `upstream` resolves once; `service update --force` |
| 10 | 192 MiB cache vs `limits.memory: 128M` |
| 11 | `limits.cpus: "0.02"` + CPU-heavy health self-test |
| 12 | debug log on tmpfs, "rotated" by `unlink` while fd stays open |
| 13 | tmpfs `nr_inodes=4096`, 5000 session files |
| 14 | entrypoint shell script without `exec` |
| 15 | iptables chain `SEC-BASELINE` on worker2 drops inbound UDP 1024-65535 (VXLAN) |
| 16 | `iptables -t raw -A OUTPUT -d manager1 --dport 2377 -j DROP` on worker1 |
| 17 | worker2 `eth0` MTU 1400 (+ TSO/GSO off on senders) |
| 18 | worker1 `prio` qdisc + `netem 400ms loss 5%` for `dport 4789` only |
| 19 | overlay subnet `172.30.0.0/16` overlaps the datacenter `172.30.0.0/24` |
| 20 | 3 managers; manager2+3 destroyed and re-created empty |

</details>
