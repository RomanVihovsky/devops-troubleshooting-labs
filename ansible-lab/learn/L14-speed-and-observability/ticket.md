# L14 · Speed and observability
**Learn** · callbacks (`profile_tasks`, `timer`), SSH multiplexing, pipelining, fact gathering/caching · ~25 min

`site.yml` does almost nothing - and still takes minutes. Find out where the time goes and make it fast.
You can't fix DNS (the network team's resolver), but the nodes' `sshd` configuration is yours - via Ansible.

1. Turn on timing: `callbacks_enabled = ansible.posix.profile_tasks, ansible.posix.timer` in `ansible.cfg`. Run
   it once and read the slowest tasks. `ansible-playbook -vvvv` shows what happens per task (count the SSH
   connections).
2. Fix the config:
   * SSH multiplexing - someone disabled `ControlMaster` "to fix stale sockets" in 2025;
   * `pipelining = True` (fewer SSH round trips per task);
   * facts: the three plays gather facts three times. Gather once - `gathering = smart` with a `jsonfile` fact
     cache (e.g. `/tmp/ansible-facts`, timeout 3600) - or switch facts off where they are not used.
3. Root cause: the nodes' sshd does reverse DNS for every connection and session (`UseDNS yes` in
   `/etc/ssh/sshd_config.d/10-dns.conf`) against a dead resolver. Add a play **at the start** of `site.yml` that
   sets `UseDNS no` there (validate with `sshd -t -f %s`, reload sshd - note the service is `ssh` on Debian but
   `sshd` on Rocky).
4. Keep host key checking on.

**Test**: a cold run of `site.yml` (no existing SSH control sockets, empty fact cache) finishes in **under 12 s**;
`UseDNS` is off on the nodes; the timing callbacks are enabled; pipelining is on and multiplexing is not disabled;
site.yml converges.
