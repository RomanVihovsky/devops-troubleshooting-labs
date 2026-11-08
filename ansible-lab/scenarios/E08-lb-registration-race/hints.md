## Hint 1
`./lab node lb1` -> `lb-register list`, `cat /usr/local/sbin/lb-register`. What happens when three copies of it run
at the same moment? A delegated task runs once **per host of the play** - in parallel, up to `forks` at a time -
even though all of them execute on lb1.

## Hint 2
Read-modify-write without a lock: each run reads the registry, validates (2 s), writes its version back. The last
writer wins and the other registrations are lost - while each run reports "added". You can't fix the tool, so
control how many copies of *that one task* run at once.

## Hint 3
The task keyword `throttle: 1` limits concurrency for one task (or block) without serializing the play:
```yaml
    - name: Register in the load balancer
      ...
      delegate_to: lb1
      throttle: 1
```
(`serial` would deploy the whole play node by node; `run_once` + a loop over `ansible_play_hosts` also works.)
