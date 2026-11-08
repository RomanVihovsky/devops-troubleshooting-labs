#!/usr/bin/python3
# Copyright: (c) 2026, ACME Platform Team
# GNU General Public License v3.0+ (see https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import annotations

DOCUMENTATION = r"""
module: app_flag
short_description: Manage feature flags of the ACME shop
version_added: 1.1.0
description:
  - Sets or removes one feature flag in the shop's flags file (C(name=value) lines).
options:
  name:
    description: Flag name.
    type: str
    required: true
  value:
    description: Flag value. Required with O(state=present).
    type: str
  state:
    description: Whether the flag should be set or removed.
    type: str
    choices: [present, absent]
    default: present
  path:
    description: The flags file the shop reads.
    type: path
    default: /etc/shop/flags.conf
author: ACME Platform Team (@acme-platform)
"""

EXAMPLES = r"""
- name: Turn on the new checkout
  acme.ops.app_flag:
    name: new_checkout
    value: "on"

- name: Remove a retired flag
  acme.ops.app_flag:
    name: old_banner
    state: absent
"""

RETURN = r"""
previous:
  description: The flag's value before the change (null if it was not set).
  type: str
  returned: always
"""

import os

try:
    import requests  # for the remote flag service (v2)
except ImportError:
    pass

from ansible.module_utils.basic import AnsibleModule


def read_flags(path):
    flags = {}
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    flags[key.strip()] = value.strip()
    return flags


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            value=dict(type='str'),
            state=dict(type='str', default='present', choices=['present', 'absent', 'enabled']),
            path=dict(type='path', default='/etc/shop/flags'),
        ),
        required_if=[('state', 'present', ['value'])],
        supports_check_mode=True,
    )
    name, value, state, path = (module.params[k] for k in ('name', 'value', 'state', 'path'))

    flags = read_flags(path)
    previous = flags.get(name)
    if state == 'absent':
        changed = name in flags
        flags.pop(name, None)
    else:
        changed = previous != value
        flags[name] = value

    if changed and not module.check_mode:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        tmp = path + '.tmp'
        with open(tmp, 'w', encoding='utf-8') as f:
            f.write('# managed by acme.ops.app_flag\n')
            f.writelines('%s=%s\n' % (k, v) for k, v in sorted(flags.items()))
        module.atomic_move(tmp, path)

    module.exit_json(changed=changed, previous=previous, msg=('flag %s %s in %s' % (name, 'removed' if state == 'absent' else 'set to %s' % value, path)) if changed else 'unchanged')


if __name__ == '__main__':
    main()
