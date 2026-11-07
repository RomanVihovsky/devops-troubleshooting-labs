# How the faults are emulated

Every scenario boots fresh containers from `linuxlab/server:1` (Debian 12, systemd as
PID 1) and runs `scenarios/NN-*/.lab/setup.sh` **on the host**, which pipes shell scripts
into the machines with `docker exec -i ... bash -s` - nothing from the setup is left on the
server for you to find. Faults are plain Linux configuration: systemd units and drop-ins,
config files, cron entries, mounts, file modes/attributes, iptables rules, resolver files,
cgroup limits.

## Techniques by area

| Area | Technique (inside the container) |
|---|---|
| runaway / respawning processes | `exec -a '[name]'` disguise, root crontab respawn loop, `Restart=always` units |
| D state / load average | cgroup v2 `MemoryHigh=` on a unit -> tasks sleep in `mem_cgroup_handle_over_high` |
| zombies | a parent that `fork()`s and never `wait()`s |
| OOM kill | `MemoryMax=` on a unit + an unbounded cache |
| fd limits | `LimitNOFILE=` drop-in vs `/etc/security/limits.conf` red herring |
| disk full / inodes | small `tmpfs` mounts (`size=`, `nr_inodes=`) from the scenario's `compose.yml` |
| deleted-open files | `rm` of a file a running service still writes to |
| attributes | `chattr +i` / `+a` (needs `CAP_LINUX_IMMUTABLE`) |
| hidden files / noexec | systemd `.mount` units: tmpfs over a populated dir, bind mount with `noexec` |
| permissions | dir modes, `StrictModes`, dotted file in `/etc/sudoers.d`, `chmod -x chmod` |
| systemd | typos in `User=`/`ExecStart=`, wrong `Type=forking`, socket activation (`.socket` on :80) |
| cron | dotted file name in `/etc/cron.d`, unescaped `%`, cron's minimal `PATH` |
| linker | library moved out of the loader path + `ldconfig` |
| DNS | `nsswitch.conf` without `dns`, stale `/etc/hosts`, dead first `nameserver` (an alias IP on lnx-dns with an iptables DROP) |
| network | service bound to `127.0.0.1` + `iptables -j DROP` |
| TLS | private CA via `openssl ca` with past `-startdate/-enddate`, renewal with a new key and no reload |
| log analysis | deterministic generator (fixed random seed) |

## Build your own scenario

```
scenarios/27-my-incident/
  ticket.md          "# Title" on line 1, symptoms + a **Test** line
  hints.md           "## Hint 1", "## Hint 2", ...
  compose.yml        which machines: source lib/mkcompose.sh; mkcompose scenarios/27-my-incident srv client
                     (srv / client / dns extend ../../infra/hosts.yml)
  .lab/setup.sh      sxi <<'S' ... S   (break things on srv; cxi for client)
  .lab/verify.sh     check / check_eventually ...; verdict
  .lab/solve.sh      the reference fix
  .lab/solution.md
```
Helpers (`lib/common.sh`): `sx`/`sxi` (root on srv), `cx`/`cxi` (client), `as_user`,
`active`, `restarts`, `mainpid`, `retry`, `remember`/`recall` (facts kept on the host),
`check`, `check_eventually`, `verdict`. Then prove it: `./lab selftest 27`.

## What the lab deliberately does NOT do

* **No privileged containers.** A privileged systemd container shares host devices
  (`/dev/kmsg`, ttys, disks) and writable `/proc/sys`. During development one froze the
  host - its journald start was the last thing the host ever logged.
* **No I/O throttling of real disks** (`--device-write-bps`, `IOWriteBandwidthMax=` on
  `/dev/sda`). Throttling writes of one cgroup on the host's root filesystem can stall the
  filesystem journal for *everyone* (priority inversion) - it froze the host the moment such
  a container started. "High load, idle CPU" is produced with `memory.high` instead.
* **No loop devices** (global kernel objects, need device access) and **no clock changes**
  (time is not namespaced). Scenarios that would need them stay in the backlog.

## Spoiler: what each scenario injects

<details>
<summary>Open only after solving (or giving up)</summary>

| # | Injected fault |
|---|---|
| 01 | `[kmetricsd]` = python busy loop, respawned by root's crontab every minute |
| 02 | `thumbnailer.service` `MemoryHigh=48M` for 4 x 25 MB workers |
| 03 | `reap_children = no` -> parent never waits |
| 04 | `CACHE_MAX_ITEMS=0` + `MemoryMax=96M` |
| 05 | drop-in `LimitNOFILE=256`, app opens 300 files; limits.conf irrelevant |
| 06 | `systemd-telemetry.service` (fake name), Restart=always, enabled |
| 07 | 56 MB journal deleted while `queue-worker` holds it open (tmpfs 64 MB) |
| 08 | tmpfs `nr_inodes=20000` full of 10-day-old session files |
| 09 | `chattr +i app.conf`, `chattr +a audit.log` |
| 10 | 6 files written before `srv-uploads.mount` (tmpfs) covered the directory |
| 11 | `opt-tools.mount` bind mount with `noexec` |
| 12 | `/srv/www` mode 0750 root:root |
| 13 | `/home/deploy` mode 0775 + StrictModes |
| 14 | `chmod -x /usr/bin/chmod` |
| 15 | `/etc/sudoers.d/deploy.conf` (dot in name -> ignored) |
| 16 | `User=inventry` + wrong `ExecStart` path |
| 17 | `Type=forking` + `PIDFile=` for a foreground app |
| 18 | `/etc/cron.d/nightly.backup` + `%` + PATH |
| 19 | `legacy-status.socket` listening on :80 (PID 1 owns the port) |
| 20 | `libjq.so.1*` moved to `/opt/vendor/lib`, cache rebuilt |
| 21 | `hosts: files myhostname` + stale `/etc/hosts` line |
| 22 | `bind = 127.0.0.1` + `iptables ... --dport 8090 -j DROP` |
| 23 | `nameserver 10.77.0.54` (black hole) listed first |
| 24 | expired cert served from memory; renewed cert needs `srv-2026.key` |
| 25 | missing `;`, asset mode 0600, `LimitNOFILE=16` + 1 worker |
| 26 | generated log: scanner IP, 37 wp-login IPs, spike at 14:37 |

</details>
