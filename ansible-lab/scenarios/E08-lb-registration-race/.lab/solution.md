# Solution - delegated tasks run in parallel per host: `throttle: 1` on the registration

**Root cause**: "Register in the load balancer" runs once for every web host, delegated to lb1 - and like every task,
in parallel (up to `forks`). `lb-register` reads the registry, validates the new config for ~2 s, then writes its
version back: three concurrent runs all start from the same (empty) registry, the last writer wins, two
registrations are lost - and each run honestly reports "added". Every deploy fixes one more node, so after a rebuild
it takes as many runs as there are nodes. (The tool's lock only covers the *apply* step - the read happened
before it: a lock in the wrong place.)

**Fix**
```yaml
    - name: Register in the load balancer
      ansible.builtin.command: "/usr/local/sbin/lb-register add {{ inventory_hostname }} {{ inventory_hostname }}:8080"
      delegate_to: lb1
      throttle: 1        # one at a time for this task only
```
Equally valid: `run_once: true` + `loop: "{{ ansible_play_hosts }}"` (one worker, sequential), or wrapping the call in
`flock` on lb1. Not acceptable: `serial: 1` / `forks = 1` (the whole deploy becomes sequential).

**Interview notes**
* `delegate_to` changes *where* a task runs, not *how often*: once per host in the play, concurrently.
* `throttle` (task/block/play) caps concurrent workers for that scope; `serial` creates batches for the whole play;
  `forks` is the global worker limit; `run_once` runs on the first host of the batch.
* Anything that edits shared state from several hosts (LB pools, DNS zones, a central config file) needs
  `throttle: 1`, `run_once` + loop, a lock, or one template rendered from `groups[...]`.
