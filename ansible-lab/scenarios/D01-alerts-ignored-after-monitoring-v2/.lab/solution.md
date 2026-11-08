# Solution - the rule matched the v1 payload; v2 is nested and targets FQDNs

**Root cause** - two silent mismatches, no error anywhere:
1. The condition `event.payload.check == "nginx" and event.payload.status == "down"` describes Monitoring 1.x.
   v2 sends `{"alert": {"check": ..., "state": "critical", "target": {"fqdn": ...}}}` - the webhook accepted
   the POST (HTTP 200), the engine found no matching rule, and an unmatched event is simply dropped.
2. With the condition fixed, the playbook ran against `hosts: web3.acme.internal` - not an inventory name:
   "Could not match supplied host pattern" (a warning) and a green, empty run.

**Fix**
```yaml
# rulebooks/web.yml
condition: event.payload.alert.check == "nginx" and event.payload.alert.state == "critical"
# remediate/nginx.yml
hosts: "{{ ansible_eda.event.payload.alert.target.fqdn | split('.') | first }}"
```
(Alternatives: pass `extra_vars: {target: ...}` from the rule, or name inventory hosts by FQDN.) Restart the
activation, re-post the alert - web3 heals.

**Interview notes**
* Event payloads are an API contract: version them, keep sample payloads in the repo, and test rulebooks
  against them (`ansible-rulebook ... --print-events`, a catch-all `debug`/`print_event` rule in staging).
* Unmatched events vanish without a trace - log/count them (a last catch-all rule) and alert on "alerts without
  remediation".
* `hosts:` patterns that match nothing only warn; for automation that must act, assert the target exists
  (`ansible_play_hosts | length > 0`) or set `ANSIBLE_HOST_PATTERN_MISMATCH=error`.
