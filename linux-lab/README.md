# linux-lab

26 classic **Linux troubleshooting interview tasks** (SadServers-style), each on a fresh,
throwaway Debian server with real systemd. You get a ticket with symptoms and a test,
a shell on the box, and `./lab verify` to prove you fixed it.

```
host ── docker network "linuxlab" 10.77.0.0/24
          ├─ lnx-srv     10.77.0.10   the broken server (systemd, nginx, sshd, cron, rsyslog)
          ├─ lnx-client  10.77.0.20   second machine, only in scenarios that need one
          └─ lnx-dns     10.77.0.53   dnsmasq, only in DNS scenarios
```

* Plan & research: [PLAN.md](PLAN.md) · How faults are emulated (+ build your own): [docs/FAULTS.md](docs/FAULTS.md)
* Separate from `../swarm-lab` - own image, network, containers and CLI.

## Quick start

```bash
./lab build          # once: builds linuxlab/server:1 (~1-2 min, needs internet)
./lab list
./lab start 01       # fresh server, broken on purpose, prints the ticket
./lab sh             # you are "admin" with passwordless sudo   (./lab sh srv root, ./lab sh client)
./lab verify         # PASS / FAIL
./lab hint           # progressive hints;  ./lab solution  when stuck
./lab stop           # throw the machines away
```
`./lab ssh` does a real `ssh admin@10.77.0.10` with a key the lab generates (your `~/.ssh` is untouched).
`./lab start random` hides which scenario you got - good interview practice. The ticket's
**Test** line tells you exactly what "fixed" means.

## Scenarios

| # | Ticket | Area |
|---|---|---|
| 01 | Killing the CPU hog doesn't help | processes, cron |
| 02 | Load is high, but the CPU is idle | D state, cgroups, PSI |
| 03 | Hundreds of `<defunct>` processes | zombies |
| 04 | The indexer keeps dying, silently | OOM killer |
| 05 | "Too many open files" | limits, systemd |
| 06 | What keeps writing to this log? | lsof, units |
| 07 | Disk full, but there is nothing on it | deleted-open files |
| 08 | "No space left on device" - but df says 99% free | inodes |
| 09 | Even root can't change this file | chattr |
| 10 | Last night's uploads vanished | mount points |
| 11 | Root gets "Permission denied" running a script | mount options |
| 12 | nginx says 403 for a world-readable file | permissions |
| 13 | SSH key login stopped working | sshd, 2 hosts |
| 14 | chmod itself lost its execute bit | puzzle |
| 15 | The deploy user's sudo rule does nothing | sudoers |
| 16 | Service won't start after "a small edit" | systemd units |
| 17 | Service hangs in "activating", then gets killed | systemd Type= |
| 18 | The backup cron job never ran | cron |
| 19 | nginx can't start: address already in use | sockets |
| 20 | error while loading shared libraries | dynamic linker |
| 21 | It's always DNS | nsswitch, hosts, 3 hosts |
| 22 | Works on localhost, not from other hosts | bind addr, iptables |
| 23 | Every request takes exactly 5 seconds extra | resolver |
| 24 | HTTPS broke - but the certificate was renewed | TLS |
| 25 | Boss fight: the shop is down after a "tuning session" | multi-fault |
| 26 | Who attacked us? Answer from the access log | awk/sort/uniq |

## Rules of the game

* Don't read `scenarios/*/.lab/` - setup, verify and solution live there (spoilers).
* Fix it like on a real server: from inside the box, with Linux tools. Some tests guard
  against shortcuts ("don't restart it", "keep the limit", "don't copy files back").
* Everything is disposable: `./lab start <id>` always rebuilds from scratch.

## Safety

The machines are **not privileged** containers: no host devices, read-only `/proc/sys`
and `/sys`, their own cgroup namespace, only the capabilities the scenarios need
(`SYS_ADMIN` for mounts, `NET_ADMIN` for iptables, `SYS_PTRACE` for strace,
`LINUX_IMMUTABLE` for chattr). systemd units that touch host-level things (logind, sysctl,
kernel modules, clock, binfmt) are masked, and no scenario throttles a real disk.
Two early prototypes (a privileged container; disk-write throttling on the host's root
disk) froze the host - see [docs/FAULTS.md](docs/FAULTS.md#what-the-lab-deliberately-does-not-do).

## Maintenance

```bash
./lab status
./lab selftest all     # every scenario must FAIL before and PASS after the reference fix (~15 min)
./lab stop && docker rmi linuxlab/server:1     # remove everything
```
