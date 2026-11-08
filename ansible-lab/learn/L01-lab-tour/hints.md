## Hint 1
YAML inventory: `all: children: web: hosts: {web1: {}, web2: {}} vars: {tier: frontend}`. Hosts are
resolved by name - `web1`/`web2` resolve inside the lab network.

## Hint 2
`ansible.cfg` sections: `[defaults]` -> `inventory`, `remote_user`, `forks`. Ansible reads `./ansible.cfg`
from the current directory (unless the directory is world-writable - more about that in incident I02).

## Hint 3
`ansible web -b -m ansible.builtin.user -a "name=deploy shell=/bin/bash"`. `-b` = become (sudo).
Note: `ansible -o` (oneline) is deprecated in 2.22 - configure callbacks instead.
