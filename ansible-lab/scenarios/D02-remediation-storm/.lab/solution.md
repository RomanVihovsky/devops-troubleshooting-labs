# Solution - throttle the rule per host (`once_within` + `group_by_attributes`)

**Root cause**: every matching event fires the rule's action. Monitoring re-sends `down` every 15 s while the
check fails; the activation queued one `run_playbook` per alert and worked through them one after another -
long after the check had recovered. Each run restarted nginx.

**Fix** (rule level, `rulebooks/web.yml`):
```yaml
    - name: Heal nginx
      condition: event.payload.check == "nginx" and event.payload.status == "down"
      throttle:
        once_within: 10 minutes          # fire on the first event, ignore repeats for 10 minutes
        group_by_attributes:
          - event.payload.host           # ... per host: web3's alert still fires while web1 is throttled
      action:
        run_playbook:
          name: remediate/nginx.yml
```
Not this: `once_after` (fires once *after* the window - 10 minutes of outage), grouping by `event.payload.check`
(one nginx alert anywhere silences all others), or `accumulate_within` + `threshold` (waits for N events).

**Interview notes**
* Automatic remediation needs brakes: throttling/deduplication, a restart budget, and escalation to a human when
  it fires repeatedly (here: a second alert inside the window could `post_event` to a paging rule).
* Make the remediation itself idempotent and state-checking (restart only if nginx is really down) - then a replayed
  alert is harmless. `run_playbook` also has `lock:` to serialize runs that must not overlap.
* Rulebook throttling is per activation (in memory): a restarted activation forgets its windows.
