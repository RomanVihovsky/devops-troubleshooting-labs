cat > rulebooks/nginx.yml <<'YML'
---
# EDA activation for the web tier. `./lab eda restart` re-reads this file; `./lab eda logs` shows what happens.
- name: Heal the web tier
  hosts: web
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5000
  rules:
    - name: Heal nginx
      condition: event.payload.check == "nginx" and event.payload.status == "down"
      action:
        run_playbook:
          name: remediate/nginx.yml

    - name: Show every other alert (debugging)
      condition: event.payload is defined
      action:
        print_event:
          pretty: true
YML
sed -i 's|^  # TODO: run_playbook.*|  # only the host from the alert (the ruleset'"'"'s hosts: web is the --limit)|; s|^  hosts: web$|  hosts: "{{ ansible_eda.event.payload.host }}"|' remediate/nginx.yml
eda_restart /work
