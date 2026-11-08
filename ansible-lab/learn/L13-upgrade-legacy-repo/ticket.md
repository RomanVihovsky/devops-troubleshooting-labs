# L13 · Upgrade a 2.16-era playbook to ansible-core 2.22
**Learn** · 2.19 templating overhaul, 2.20 fact injection deprecation, 2.22 removals · ~30 min

`site.yml` was written for ansible-core 2.16 and has not been touched since. On 2.22 it fails at the first
task - and behind that error wait several more. Port it, one error at a time:

1. Embedded templates in expressions (`that: "{{ ... }} > ..."`).
2. `loop: "{{ range(...) }}"`.
3. A non-boolean condition (`create_dirs: "yes"`).
4. `{{ omit }}` inside loop items.
5. Facts as top-level variables (`ansible_distribution`): deprecated since 2.20, **gone by default in 2.24**.
6. `play_hosts` (deprecated, removed in 2.23) and `follow_redirects: yes` (removed in 2.22).

Expected result on every web node: `/var/spool/acme/q1`..`q3` (0750), `/etc/acme/app.conf` (0640),
`/etc/acme/legacy.conf`, `/etc/acme/os.txt` = `<Distribution> <major> (2 hosts in play)`.

**Test**: the playbook runs on 2.22 **without a single deprecation warning**, also with fact injection
switched off (`INJECT_FACTS_AS_VARS=False`, the 2.24 default); the nodes match the spec; `create_dirs: false`
really skips the spool directories; site.yml converges.
