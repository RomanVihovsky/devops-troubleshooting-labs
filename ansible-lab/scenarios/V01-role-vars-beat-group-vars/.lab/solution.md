# Solution - tunables belong in defaults/, not vars/

**Root cause**: `appserver_workers` was defined in the role's `vars/main.yml`, which beats inventory group_vars.
The group_vars value was silently ignored.

**Fix**: tunables to `defaults/main.yml` (lowest precedence, meant to be overridden); keep `vars/` for constants.

**Interview notes**
* Precedence cheat sheet (low -> high): role defaults · inventory group_vars (all -> groups -> child groups) ·
  host_vars · play vars/vars_files · **role vars** · block/task vars · include_vars · set_fact/registered ·
  role/include params · extra vars.
* `ansible-playbook --check --diff` and `debug: var=...` per host show the effective value.
* Argument specs (L06) document which knobs a role offers.
