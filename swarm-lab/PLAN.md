# swarm-lab - plan

A local Docker Swarm "datacenter" that is broken on purpose, one incident at a
time, so you can practise troubleshooting with Linux and Docker skills. Spoiler-free:
root causes live only in `scenarios/*/.lab/` and `./lab solution`.

## 1. Goals

| Goal | How |
|---|---|
| Realistic multi-node swarm on one laptop | 3 Docker-in-Docker "VMs" (1 manager, 2 workers) + 2 optional managers for HA |
| Faults must never touch the host | every fault happens *inside* a node container's own network namespace / dockerd |
| One problem per incident (1:1) | each scenario = one compose file deployed as stack `app` + one injected fault |
| You can check your own work | `./lab verify` tests the **outcome** (service healthy, traffic flows), not *how* you fixed it |
| Learn, not just pass | progressive hints, a written root-cause/solution per scenario, a `selftest` that proves each scenario breaks and can be fixed |
| No internet needed at runtime | images are seeded from the host into a private registry inside the lab |

## 2. Architecture

```
 host (your Linux box, docker CLI)                         ./lab  (bash CLI)
 ─────────────────────────────────────────────────────────────────────────────
  docker bridge "swarmlab"  172.30.0.0/24   ("the datacenter network")
   ├─ lab-manager1  172.30.0.11  ┐
   ├─ lab-worker1   172.30.0.21  ├─ privileged docker:dind = "VMs"; each runs its own
   ├─ lab-worker2   172.30.0.22  ┘  dockerd, iptables, tc, routes  -> swarm nodes
   ├─ lab-manager2/3 .12/.13        (profile "ha", only for the quorum scenario)
   ├─ lab-registry  172.30.0.5      registry:5000 (plain HTTP, all lab images)
   └─ lab-legacy-api 172.30.0.50    a non-swarm dependency (:8080)

  inside the swarm: overlay networks 10.10.0.0/16 (default pool), routing mesh on :8080
  you reach the app from the host at http://172.30.0.{11,21,22}:8080
```

* `infra/compose.yml` - the datacenter (nodes, registry, legacy API).
* `infra/node/` - node image: `docker:29-dind` + tcpdump, iproute2/tc, iptables,
  nsenter, strace, lsof, dig, mtr, iperf3, ...
* `images/webapp/` - one tiny stdlib-Python app used by all scenarios; behaviour
  is driven by ordinary-looking env vars (REDIS_HOST, LOG_LEVEL, SESSION_DIR, ...).
* `scenarios/NN-name/` - one directory per incident (see section 4).
* `workspace/` - copy of the current scenario's files, mounted at `/lab/workspace`
  on every node. Edit here and redeploy; the originals stay pristine.

## 3. Lab mechanics

| Step | Command | What happens |
|---|---|---|
| build & boot | `./lab up` | build node image, start nodes, `swarm init` + join, seed registry |
| start incident | `./lab start 07` | full reset, copy files to `workspace/`, deploy stack `app`, inject fault, print ticket |
| investigate | `./lab sh worker2`, `docker ...`, `curl ...` | you are root on the "VM" |
| fix | edit `workspace/stack.yml` + `./lab deploy`, or fix the node | |
| check | `./lab verify` | PASS / FAIL per acceptance criterion |
| help | `./lab hint` (x3), `./lab solution`, `./lab solve` | progressive |
| clean | `./lab reset [--hard]` | remove stack, undo recorded faults, restore daemon.json, labels, images |

**Verification design.** Each `verify.sh` asserts the ticket's "Done when" list:
convergence (`N/N` replicas), stability (no task replaced during a window),
traffic through *every* node's routing mesh, latency/size thresholds, and
guard-rails that block shortcut fixes (e.g. "cache size must stay 192 MiB",
"node must not be rebooted", "service must be the original one").

**Fault bookkeeping.** Faults are injected with `inject <node> '<do>' '<undo>'`;
the undo command is stored on the host (`.state/undo/`) so `reset` can always
clean up, even if you only half-fixed something. `reset --hard` restarts all node
containers (fresh network namespaces) as a last resort.

## 4. Scenario catalog

Each scenario directory:

```
scenarios/NN-name/
  ticket.md        the incident as reported (symptoms only)
  hints.md         3-4 progressive hints
  files/           stack.yml (+ configs/secrets) -> copied to workspace/
  .lab/setup.sh    deploys + injects the fault        (spoiler)
  .lab/verify.sh   acceptance checks                  (mild spoiler)
  .lab/solve.sh    reference fix (used by selftest)   (spoiler)
  .lab/solution.md root cause, diagnosis commands, fix, real-world notes
```

| # | Incident (symptom) | Area | Skills you practise |
|---|---|---|---|
| 01 | Shop database never starts | scheduling | `service ps --no-trunc`, node labels, constraints |
| 02 | Reports service never gets a container | scheduling | node resources, reservations vs limits |
| 03 | report-api runs only one replica | images | per-node image stores, registries, digests |
| 04 | Global agent missing on one node | daemon config | config drift, `docker info`, daemon.json, SIGHUP reload |
| 05 | Web replicas keep restarting | health | exit codes, `State.Health`, what's inside an image |
| 06 | Crash loop after moving password to a secret | secrets | `service logs`, secret mounts |
| 07 | 502 after network segmentation | overlay/DNS | embedded DNS 127.0.0.11, service networks |
| 08 | Config change cannot be deployed | configs | immutable objects, rolling updates |
| 09 | 502/504 from proxy after every redeploy | DNS/LB | VIP vs dnsrr, resolver caching |
| 10 | web dies with exit code 137 | cgroups/memory | OOM killer, `dmesg`, `memory.events` |
| 11 | never healthy after "right-sizing" | cgroups/CPU | CFS quota, `cpu.stat` throttling |
| 12 | Disk full, but nothing on the disk | filesystem | `df` vs `du`, `/proc/<pid>/fd`, `lsof +L1` |
| 13 | "No space left" with 99% free | filesystem | inodes (`df -i`), volume option immutability |
| 14 | Every deploy takes minutes | processes | PID 1, signals, `stop_grace_period`, init |
| 15 | Half of the requests hang | firewall | swarm ports, `tcpdump`, `iptables-save`, custom chains |
| 16 | worker1 is Down but the VM is fine | firewall | heartbeats/2377, iptables tables, `nc`, local drops |
| 17 | Downloads hang through one LB node | MTU | VXLAN overhead, `ping -M do`, black holes |
| 18 | p90 terrible, ping perfect | traffic control | `tc qdisc/filter`, netem, selective delay |
| 19 | Legacy API unreachable from containers only | routing | `nsenter`, `ip route get`, overlapping subnets |
| 20 | Two managers lost, swarm headless | Raft / DR | quorum, `--force-new-cluster`, re-joining managers |

Difficulty grows roughly with the number: 01-09 swarm mechanics, 10-14 Linux
process/resource internals, 15-19 network infrastructure, 20 disaster recovery.
`./lab start random` picks one without telling you which.

## 5. How network & infra faults are emulated

See [docs/FAULT-INJECTION.md](docs/FAULT-INJECTION.md): `tc netem` (latency, loss,
rate, selective by port), `iptables` in different tables/chains, MTU changes,
DNS breakage, frozen/crashed nodes, cgroup limits, tmpfs volumes with tiny
size/inode budgets, daemon.json drift, Raft quorum loss - and how to build your
own scenario with `./lab inject` or a new `scenarios/NN-*/` directory.

## 6. Verification of the lab itself

`./lab selftest all` runs, for every scenario: start -> verify (**must FAIL**) ->
reference solve -> verify (**must PASS**). This proves each incident is really
broken and really fixable with the documented solution.

## 7. Backlog (ideas for more scenarios)

* encrypted overlay with IP protocol 50 (ESP) blocked
* clock skew breaking swarm mTLS (needs libfaketime - time is not namespaced)
* swarm autolock after a manager restart (`docker swarm unlock`)
* failed rolling update stuck in `paused` (`update_config.failure_action`)
* `ulimits: nofile` too low under load ("Too many open files")
* `docker_gwbridge` subnet colliding with a VPN route
* conntrack table full / ephemeral port exhaustion (`ip_local_port_range`)
* host-mode published ports vs routing mesh
