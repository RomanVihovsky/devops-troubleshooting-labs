# Solution - L14

Reference `ansible.cfg`: `.lab/solve.sh`.

**Takeaways**
* Measure first: `profile_tasks`/`timer` (ansible.posix), `-vvvv` for SSH details; `ANSIBLE_DEBUG=1` is the
  last resort (2.22: it can print `no_log` values before masking - never in CI).
* SSH is the cost driver: ControlPersist reuses one connection per host; pipelining runs modules over that
  connection without temp-file round trips (needs `requiretty` off in sudoers - the default on modern distros).
  Overriding `ssh_args` drops the defaults silently.
* Facts: gather once (`gathering = smart` + fact cache), `gather_subset`, or `gather_facts: false` where unused.
* Then: `forks` for many hosts, `strategy: free` for independent hosts, async for long tasks.
* Root cause: `UseDNS yes` + a dead resolver costs seconds per SSH connection **and per session** - every
  file transfer of `copy`/`template` opens extra channels (16-18 s per task here). Tuning alone got the run from
  minutes to ~20 s; fixing sshd via Ansible got it to ~4 s. Measure, fix the cause, then tune.
