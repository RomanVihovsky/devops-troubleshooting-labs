# Solution - role variables share one namespace: prefix them

**Root cause**: the `web` role has `port: 8080` in `defaults/`, the new `metrics` role has `port: 9100` in
`vars/`. With `roles:`, every role's vars are visible to the whole play, and role vars (precedence 15) beat role
defaults (precedence 2) - so the shop's task rendered `listen 9100`.

**Diagnose**: `ansible-playbook site.yml --check --diff` shows the shop's config switching to 9100;
`git log` shows that only the metrics role was added; `grep -rn '^port:' roles/`.

**Fix**: `web_port`, `metrics_port` - every role variable prefixed with its role name.

**Interview notes**
* A task always sees its *own* role's defaults above other roles' defaults - but another role's `vars/` still win.
  That asymmetry is why such leaks appear only "sometimes".
* ansible-lint `var-naming[no-role-prefix]` enforces prefixes (it is part of the `basic` and stricter profiles).
* `DEFAULT_PRIVATE_ROLE_VARS=True` or `include_role` (private by default) limit exposure; prefixes are still the
  only robust convention across roles you don't control.
* Same class of bug: two roles notifying handlers with the same name (handlers are global too).
