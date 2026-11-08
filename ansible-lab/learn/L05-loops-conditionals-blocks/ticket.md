# L05 · Loops, conditionals and blocks
**Learn** · loop/loop_control, boolean conditions (2.19+), block/rescue/always, changed_when · ~25 min

`group_vars/web.yml` lists the team accounts. Write `users.yml`:

1. One task with `loop` over `team`: create each user whose `state` is `present` (shell, groups `wheel` on
   Rocky / `sudo` on Debian - decide with `ansible_facts['os_family']`), remove the ones marked `absent`.
   Use `loop_control: label` so the output shows names, not whole dicts.
2. Conditions must be **booleans** - since ansible-core 2.19 a string is not a condition.
3. A `block` that installs the optional package `acme-agent` (it is **not** in the mirror);
   `rescue`: write `/etc/acme/agent-missing` so monitoring notices; `always`: make sure `/etc/acme` exists.
4. Report the number of local users with a `command` (`getent passwd`) that never reports `changed`.

**Test**: alice and bob exist with the right admin group per OS, carol is gone; `/etc/acme/agent-missing`
exists on both nodes; users.yml converges (check mode: no changes).
