## Hint 1
Did a rule fire at all? `./lab eda logs` shows the POST but no "Heal nginx" and no playbook. Compare the
rule's condition with what Monitoring 2.0 sends (`docs/alerts/v2-*.json`). To see exactly what the engine
gets, add a last rule `condition: event.payload is defined` with `action: {print_event: {pretty: true}}`,
`./lab eda restart`, then `./lab eda post docs/alerts/v2-nginx-critical.json`.

## Hint 2
v2 nests everything: `event.payload.alert.check`, `event.payload.alert.state == "critical"`,
`event.payload.alert.target.fqdn`. Once the rule fires, read the playbook output in the activation log
carefully - a green run can still do nothing.

## Hint 3
"Could not match supplied host pattern, ignoring: web3.acme.internal" - the inventory says `web3`. Map the
FQDN to the inventory name, e.g. in `remediate/nginx.yml`:
`hosts: "{{ ansible_eda.event.payload.alert.target.fqdn | split('.') | first }}"`. Restart the activation and
post the v2 critical alert to heal web3.
