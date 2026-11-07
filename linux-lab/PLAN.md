# linux-lab - plan (draft for approval)

A local break/fix playground for **classic Linux troubleshooting interview tasks**:
you get a "server" with a symptom, a root shell, and a `verify` that tells you when
it's really fixed. Same workflow as `../swarm-lab` (`./lab start 07`, `./lab hint`,
`./lab verify`, `./lab selftest`).

## 1. What the research says gets asked

| Source | Takeaway |
|---|---|
| SadServers ("LeetCode for Linux", also used by hiring teams) | Each task = a broken server + a test command. Categories: Linux/Bash, systemd, networking/DNS, storage, SSH/firewall, libraries, cron, nginx. Well-known tasks: *Saint John* (what is writing to this log file? - lsof), *Jakarta* (it's always DNS - nsswitch), *Karakorum* (file-access-control puzzle), *Cape Town* (borked nginx - open-file limits) |
| Interview guides (tecmint, kodekloud, PracHub, dev.to SRE series, testgorilla) | Recurring questions: disk full but `du` small (deleted-open file), no space but `df` free (inodes), high load with idle CPU (I/O wait / D state), zombies (kill the parent), OOM killer, too many open files, permission denied beyond rwx (ACL/attr/mount options), systemd service won't start, cron not running, port already in use, DNS, firewall vs bind address |
| PracHub SRE guide | Grade the *method*: scope -> observe -> narrow -> mitigate -> verify. Our tickets + verify follow that |

## 2. Architecture

```
host ── docker bridge "linuxlab" 10.77.0.0/24
          ├─ lab-srv      the broken "server": Debian 12 + real systemd (PID 1), nginx,
          │               openssh, cron, rsyslog/journald, python3, redis, sudo, logrotate
          │               + tools: strace lsof sysstat(iostat/pidstat) iotop htop ss tcpdump
          │                 dig/nslookup iptables inotify-tools ltrace gdb namei getfacl
          ├─ lab-client   second host for "works locally, not remotely" / SSH tasks
          └─ lab-dns      tiny DNS server for the DNS scenarios
```
* One privileged container per role (systemd needs it; loop devices, mounts,
  iptables, cgroup I/O throttling stay inside the container).
* **Each scenario has its own `compose.yml`** (1-3 containers) + `setup.sh` that breaks
  things after boot. Fresh containers per start -> no leftovers between scenarios.
* Some scenarios log you in as an **unprivileged user** (`./lab sh` -> `ops`, with sudo
  where the story needs it), because "you're root" kills half the puzzles.
* Verify = SadServers-style test commands run from outside (curl from lab-client,
  `systemctl is-active`, file contents...), checking the *outcome*, plus guard rails
  against shortcuts (e.g. "data in /data must survive", "service must survive a restart").
* Needs internet once to build the Debian image (~250 MB); runtime is offline.

## 2b. Environment & lifecycle

**Separate from swarm-lab**: own image (`linuxlab/server`), own network
(`linuxlab`, 10.77.0.0/24), own container names (`lnx-*`), own `./lab` CLI. Both
labs can exist side by side; nothing is shared, and neither touches your host
config (no sudo, no host iptables/sysctl, no packages installed on the host).

**Ephemeral, one scenario at a time** - unlike swarm-lab there is no long-lived
cluster. Each start builds a fresh "server" from the image and throws it away after:

```
./lab start 12
  ├─ compose down -v (previous scenario, if any)        -> clean slate
  ├─ compose -f scenarios/12-*/compose.yml up -d         -> lnx-srv (+ lnx-client/lnx-dns)
  ├─ wait for systemd "running"                          -> real boot: nginx, sshd, cron...
  ├─ .lab/setup.sh runs inside lnx-srv                   -> breaks it
  └─ prints the ticket + the test command

./lab sh            -> login shell on lnx-srv (as "ops" or root, per scenario)
./lab sh client     -> the second host, where the scenario has one
...you investigate & fix with normal Linux tools...
./lab verify        -> runs the checks (from host / lnx-client), PASS or FAIL
./lab hint | solution | solve
./lab stop          -> compose down -v, everything gone
```

| | swarm-lab | linux-lab |
|---|---|---|
| unit of work | one long-lived 3-node swarm | one throwaway server per scenario |
| reset between tasks | undo faults on the same nodes | delete & recreate containers (~5 s) |
| you work as | root on nodes | `ops` user or root, per scenario |
| network | 172.30.0.0/24 | 10.77.0.0/24 |

**Login**: no SSH needed. `./lab sh` = `docker exec` straight into a login shell
(`su - ops` or root). Optional realism: `./lab ssh` does a real
`ssh ops@10.77.0.10` with a key the lab generates (sshd runs inside the server
anyway; the host's own `~/.ssh` is never touched). Scenario 13 uses real SSH
between `lnx-client` and `lnx-srv`, entirely inside the lab.

**Isolation boundary (honest version)**: the server runs *privileged* (needed for
systemd, mounts, loop devices, iptables). Everything the scenarios break lives in
the container's own namespaces (its processes, mounts, network, users, files).
Things Linux does **not** namespace are left alone on purpose: system clock, kernel
modules, global sysctls - that's why there's no "clock skew" task. Privileged is not
a security sandbox, so it's a training lab, not a place to run untrusted code.
Full-VM isolation (Vagrant/multipass) would need nested virtualization, which your
VirtualBox VM probably doesn't expose.

**Resources**: ~300 MB RAM per running scenario, ~1 GB disk for the image.

## 3. Scenario catalog (symptoms only - root causes are spoilers in each scenario)

| # | Ticket (symptom) | Area | Skills |
|---|---|---|---|
| **A** | **Processes & resources** | | |
| 01 | Load average 40, killing the CPU hog doesn't help | CPU | `top`, `ps --forest`, PPID, cron/timers |
| 02 | Load is high but CPU is idle | D state | `ps` wchan, PSI `/proc/pressure`, cgroup `memory.high` throttling |
| 03 | Thousands of `<defunct>` processes | processes | zombies, PPID, reaping, SIGCHLD |
| 04 | The worker dies every night, nothing in its logs | memory | OOM killer, `dmesg`/journal, `oom_score_adj`, leaks |
| 05 | "Too many open files" under load | limits | `/proc/<pid>/limits`, `ulimit` vs systemd `LimitNOFILE` |
| 06 | Something keeps writing to this log - what? | files | `lsof`, `fuser`, `inotifywait`, auditing *(Saint John)* |
| **B** | **Disk & filesystems** | | |
| 07 | Disk 100% full, `du` finds almost nothing | disk | deleted-but-open files, `lsof +L1`, truncation |
| 08 | "No space left on device", `df -h` shows 70% free | disk | inodes, `df -i`, finding file swarms |
| 09 | Even root can't modify this file | attrs | `lsattr`/`chattr`, immutable/append-only |
| 10 | Uploaded files vanished after a reboot | mounts | data hidden under a mount point, `fstab`, `findmnt` |
| 11 | Root gets "Permission denied" running a script | mounts | `noexec`, mount options, interpreters |
| **C** | **Permissions & users** | | |
| 12 | nginx returns 403 for a file that is 644 | perms | parent dir `x` bit, `namei -l`, ownership |
| 13 | SSH key login stopped working | ssh | `StrictModes`, home/`.ssh` perms, sshd logs (2 hosts) |
| 14 | `chmod` itself lost its execute bit | puzzle | recover without reinstall *(Karakorum-style)* |
| 15 | The deploy user can no longer sudo | sudo | `/etc/sudoers.d` syntax/perms, `visudo -c` |
| **D** | **systemd, cron, libraries** | | |
| 16 | Service won't start after "a small edit" | systemd | `systemctl status`, `journalctl -u`, unit syntax, `daemon-reload` |
| 17 | Service hangs in `activating`, then gets killed | systemd | `Type=` mismatch, timeouts, PID files |
| 18 | Nightly backup cron job never ran | cron | cron env/PATH, `%` escaping, `cron.d` naming, logs |
| 19 | nginx can't start: address already in use | ports | `ss -ltnp`, `fuser`, socket units, stray processes |
| 20 | `error while loading shared libraries` | linker | `ldd`, `ldconfig`, `ld.so.conf.d`, `LD_LIBRARY_PATH` |
| **E** | **Networking** | | |
| 21 | It's always DNS - curl can't resolve, `dig` can | DNS | `nsswitch.conf`, `/etc/hosts`, `getent` *(Jakarta)* |
| 22 | Works on localhost, not from the client host | network | bind address, `ss`, iptables, `tcpdump` (2 hosts) |
| 23 | Every outgoing request takes exactly 5 s extra | DNS | dead first nameserver, resolver timeouts, `strace` |
| 24 | HTTPS broke overnight | TLS | `openssl s_client`, expiry, key/cert mismatch, chain |
| **F** | **Boss fights** | | |
| 25 | Borked nginx: the site is down | multi | 2-3 chained faults (config + limits + perms) *(Cape Town-style)* |
| 26 | Who attacked us? Answer from the access log | text | `awk`/`sort`/`uniq`/`grep` log analysis, answer file |

Difficulty: A/B/C easy-medium, D/E medium, F hard. `./lab start random` for interview simulation (timer optional: `./lab start 12 --timer 15m`).

## 4. Build steps (after approval)

1. Base image (`debian:12` + systemd + services + tools) and the `lab` CLI (reuse swarm-lab's framework: start/verify/hint/solution/solve/selftest/reset).
2. Scenarios 01-26: `ticket.md`, `hints.md`, `compose.yml`, `.lab/{setup,verify,solve}.sh`, `solution.md`.
3. `./lab selftest all` - every scenario must FAIL before and PASS after the reference fix.
4. README + "how each fault is emulated" doc.

**Safety rule (learned the hard way)**: never privileged, never throttle a real host disk (both froze the host). Faults stay inside container namespaces/cgroups.
