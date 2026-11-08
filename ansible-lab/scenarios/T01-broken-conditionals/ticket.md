# CI image upgraded to ansible-core 2.22 - every deploy fails
**OPS-214** · P1 · Reporter: platform

The CI image moved from ansible-core 2.17 to 2.22 yesterday (`requirements-ci.txt`). Since then
`ansible-playbook site.yml` fails on every host, e.g.
`Conditional result (True) was derived from value of type 'str' at '/work/group_vars/all.yml:1:11'. Conditionals must have a boolean result.`
Nothing changed in the playbooks. Someone found `ALLOW_BROKEN_CONDITIONALS` and wants to set it in `ansible.cfg`.

Make the repo correct for 2.22 - no escape hatches. The conditions must keep working (TLS off really
switches TLS off; the settings validation still rejects bad settings).

**Test**: `site.yml` converges on 2.22 without changes; `enable_tls: false` skips the TLS task;
an empty `app_name` is still rejected; `ALLOW_BROKEN_CONDITIONALS` is not used anywhere.
