# L15 · Event-Driven Ansible - heal nginx from a monitoring webhook
**Learn** · ansible-rulebook 1.3, the `ansible.eda.webhook` source, conditions on `event.payload`, `run_playbook`, `ansible_eda.event` · ~30 min

Monitoring posts an alert to a webhook whenever a check changes state (samples: `docs/alerts/`). Instead of
paging someone at 3 a.m. for a dead nginx, let an EDA **activation** heal it. The lab runs one for you:
`ans-eda` runs `ansible-rulebook --rulebook rulebooks/nginx.yml -i inventory/hosts.yml` on this repo (what an
activation in EDA controller does in a decision environment) and listens on `http://eda.acme.internal:5000/endpoint`.

1. In `rulebooks/nginx.yml` add the rule **Heal nginx**: its condition matches nginx `down` alerts (look at
   the alert JSON: the webhook source puts the body under `event.payload`), its action runs
   `remediate/nginx.yml` with `run_playbook`. Rules are evaluated in order - put it before the debugging rule.
2. `run_playbook` runs the playbook against **every host of the ruleset's `hosts:`**. Make
   `remediate/nginx.yml` touch only the host named in the alert (`ansible_eda.event.payload.host`) - a dead
   nginx on one node must not restart the whole tier.
3. Recovery alerts (`status: up`) and other checks (`check: disk`) must not run anything.
4. Try it: `./lab eda restart` (re-reads the repo), `./lab node web1` -> `systemctl stop nginx`,
   `./lab eda post docs/alerts/nginx-down.json`, then `./lab eda logs`.

**Test**: the activation starts from a CI checkout of the repo; with nginx stopped on web1, a `down` alert for web1
brings it back within 60 s, serving the shop page; web3's nginx is not restarted; an `up` alert for a stopped nginx
and a `disk` alert change nothing; site.yml converges.
