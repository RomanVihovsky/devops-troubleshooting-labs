# L01 · Lab tour: inventory, ad-hoc commands, ansible.cfg
**Learn** · inventory, ad-hoc, facts, become, configuration · ~20 min

You are on the controller (`./lab sh`, ansible-core 2.22). Two fresh nodes wait: `web1` (Debian 12) and
`web2` (Rocky 9), user `ansible` with your SSH key and sudo.

1. `inventory/hosts.yml` knows only web1. Add web2, put both in a group `web`, and give the group the
   variable `tier: frontend`. Check with `ansible-inventory --graph` and `ansible-inventory --host web2`.
2. `ansible.cfg`: make `inventory/hosts.yml` the default inventory, `remote_user = ansible`, `forks = 20`.
   Compare `ansible-config dump --only-changed` before and after (2.22 shows all plugin types by default).
3. `ansible all -m ansible.builtin.ping`, then facts: `ansible web -m ansible.builtin.setup -a 'filter=ansible_distribution*'`.
4. Ad-hoc with privilege escalation: create user `deploy` (shell `/bin/bash`) on every web node with
   `ansible.builtin.user` (`-b`). Run it twice - the second run is green (`ok`), not yellow (`changed`).

**Test**: the inventory has group `web` = web1 + web2 with `tier: frontend`; `ansible.cfg` sets the inventory,
remote user and 20 forks; `ansible all -m ping` works without `-i`; user `deploy` exists on both nodes.
