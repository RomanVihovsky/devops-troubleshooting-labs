# Solution - a rule on event.payload, run_playbook, and a playbook scoped to the alert's host

**Rulebook** (`rulebooks/nginx.yml`)
```yaml
- name: Heal the web tier
  hosts: web                     # the inventory scope: becomes run_playbook's --limit
  sources:
    - ansible.eda.webhook: {host: 0.0.0.0, port: 5000}
  rules:
    - name: Heal nginx
      condition: event.payload.check == "nginx" and event.payload.status == "down"
      action:
        run_playbook:
          name: remediate/nginx.yml
    - name: Show every other alert
      condition: event.payload is defined
      action: {print_event: {pretty: true}}
```
**Remediation** (`remediate/nginx.yml`): `hosts: "{{ ansible_eda.event.payload.host }}"`.

**Why**
* The webhook source wraps the request: `event.payload` = the JSON body, `event.meta` = headers, endpoint,
  received_at. Conditions are evaluated by the Drools engine; an event that matches a rule is consumed - order
  your rules from specific to generic.
* `run_playbook` passes the triggering event as the extra var `ansible_eda.event` and limits the run to the
  ruleset's `hosts:` - without scoping, one dead nginx restarts the whole tier.

**Interview notes**
* EDA = sources (webhook, Kafka, Alertmanager, ...) -> rulebook (rules: conditions + actions) -> actions
  (`run_playbook`, `run_job_template` in AAP, `post_event`, `set_fact`, `debug`). In AAP the activation runs in a
  *decision environment* (an EE for ansible-rulebook) and usually calls job templates.
* Guard rails for automatic remediation: scope to one host, throttle (D02), idempotent playbooks, alert on
  repeated remediation, and a kill switch (disable the activation).
