# Ansible interview questions (ansible-core 2.22 era)

Level: (J) junior · (M) mid · (S) senior. Each answer lists the key points a good answer contains;
`[T02]` = the lab where you practise it.

## Basics, inventory & connection

1. **(J) What does Ansible need on a managed Linux node?** - SSH + Python (modules are Python, copied and run
   remotely); no agent. Without Python only `raw` works - use it to bootstrap. [L01, I04]
2. **(J) Where does Ansible read its configuration from, and in which order?** - `ANSIBLE_CONFIG`,
   `./ansible.cfg`, `~/.ansible.cfg`, `/etc/ansible/ansible.cfg` - first found wins, no merging. A world-writable
   CWD is ignored as a config source. `ansible-config dump --only-changed`. [L01, I02]
3. **(J) What is idempotence and why does it matter?** - a second run changes nothing; modules compare desired vs
   actual state; it makes runs safe to repeat and drift visible. [L02, E01]
4. **(M) "Host key verification failed" after a node rebuild - what do you do?** - verify the new key out of
   band, `ssh-keygen -R` + `ssh-keyscan`/managed known_hosts; never `host_key_checking = False` as a fix. [I01]
5. **(M) Group names and group_vars: what can go wrong?** - file name must match the group exactly; invalid
   characters (`-`) are transformed/warned; `ansible-inventory --graph --vars` shows the truth. [I03, L09]
6. **(M) become to an unprivileged user fails with "Failed to set permissions on the temporary files" - why?** -
   the module file must be readable by the target user: needs `acl` (setfacl), or pipelining; never
   `allow_world_readable_tmpfiles`. [I06]
7. **(M) How do you handle sudo passwords?** - `ansible_become_password` from vault per group, or NOPASSWD by
   policy; `-K` only interactively. [I05]
8. **(S) Static vs dynamic vs constructed inventory?** - YAML/INI files; plugins (cloud, CMDB) with caching;
   `constructed` builds groups from vars (`keyed_groups`, `groups`, `compose`) without another API. [L09]

## Variables & precedence

9. **(J) Name variable sources from lowest to highest precedence.** - role defaults < inventory vars
   (group_vars all < group < host_vars) < facts < play vars < role vars < block/task vars < include_vars /
   set_fact < extra vars (`-e`, always win). [L03, V01]
10. **(M) A group_vars change has no effect. First suspect?** - the role sets it in `vars/main.yml` (beats
    inventory) - tunables belong in `defaults/`. [V01]
11. **(M) How do dicts behave when overridden?** - replaced, not merged (`hash_behaviour=merge` is deprecated);
    use `defaults | combine(overrides, recursive=True)`. [V02]
12. **(M) Why prefix role variables?** - roles in a play share one namespace; another role's `vars/` beat your
    defaults; ansible-lint `var-naming[no-role-prefix]`. [V04, L06]
13. **(M) `--limit web` breaks a template that uses `hostvars['db1']` - why?** - facts exist only for hosts that
    ran in this execution (or a warm fact cache); `setup` with `delegate_to` + `delegate_facts: true`. [V03]
14. **(S) `ansible_distribution` vs `ansible_facts['distribution']`?** - injected top-level facts are deprecated
    (2.20) and off by default in 2.24 (`INJECT_FACTS_AS_VARS`); use `ansible_facts`. Careful with
    `| default()` on facts - it hides the breakage. [T04, L13]

## Templating (2.19+ data tagging) & upgrades

15. **(M) What changed in 2.19's templating?** - native types throughout, conditionals must be booleans, embedded
    templates in expressions deprecated (off in 2.23), untrusted data is never templated, `omit` in data removes
    the key, non-storable results (`range`) error, error messages carry the origin. [L13, T01-T07]
16. **(J) Why is `when: "{{ x }}"` wrong?** - `when` is already an expression; templating delimiters are
    deprecated (removed in 2.23); `when: "'{{ h }}' in groups.prod"` silently compares a literal once
    embedded templates are off. [T02]
17. **(M) "Conditional result was 'yes' of type 'str'" - fix?** - real booleans in vars or `| bool`;
    `ALLOW_BROKEN_CONDITIONALS` is a temporary migration switch, not a fix. [T01]
18. **(M) A file lookup with `{{ }}` inside is no longer rendered - why, and the fix?** - trust model: lookup
    results are untrusted data; use the `template` module or `lookup('template', ...)`. [T07]
19. **(M) A list rendered into a config file shows `['a', 'b']`. Fix?** - `join(' ')`; string filters on lists
    render the repr; null renders empty - guard optional directives with `{% if %}`. [T06]
20. **(S) How do you prepare a large repo for the next core release?** - run CI with the future defaults
    (`ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=False`, `ANSIBLE_INJECT_FACT_VARS=False`), treat deprecations as
    failures, ansible-lint with the matching version, porting guides. [T02, T04, L13]

## Playbooks, handlers & execution

21. **(J) When do handlers run?** - at the end of each tasks section / play (or `meta: flush_handlers`), once,
    only on notified hosts, in definition order. [L04, R01]
22. **(M) A failed run left a config deployed but not active - why, and prevention?** - the failed host's
    pending notifications are dropped; later runs see no change. Reload once by hand; `flush_handlers` before
    dependent tasks; `force_handlers`. [R01, P03]
23. **(M) `import_role` vs `include_role`?** - static vs dynamic; tags/when are inherited by imported tasks, on
    includes they apply to the include only (`apply:`); `--list-tasks` shows the difference. [R02]
24. **(M) `command`/`shell` always report changed. Options?** - use a module; `creates`/`removes`; parse output
    for `changed_when`; `changed_when: false` only for reads. [E01]
25. **(M) What does check mode do with `command`?** - skips it; registered results are placeholders (2.22:
    `rc: 0`, empty stdout); use `check_mode: false` on read-only commands. [E03]
26. **(M) `lineinfile` keeps appending lines - why?** - the regexp doesn't match the line after the change; it
    must match before and after. For whole files/drop-ins use `template`. [E02]
27. **(M) `async` + `poll: 0` - when and how?** - fire-and-forget for long or parallel jobs; must be awaited with
    `async_status` + `until` before using the result. [E05]
28. **(S) Design a zero-downtime rolling deploy.** - `serial` (+ ramp), `max_fail_percentage: 0`, drain via the
    LB (`delegate_to`), health gate (`uri` + `until`), re-enable, one-time steps in a separate play. [L10, E04]
29. **(S) `run_once` with `serial`?** - once per batch, not per play; use a separate play or
    `ansible_play_hosts_all[0]`, plus idempotent migration tooling. [E06, L10]
30. **(S) How do you speed up a slow playbook?** - measure (`profile_tasks`, `timer`); forks, pipelining +
    ControlPersist, gather facts once (`gather_facts: false`, `gathering = smart`, fact cache), lists for package
    modules, `strategy: free`, async; fix the hosts (sshd `UseDNS`). [L14, X04]

## Roles & collections

31. **(J) Role structure and what goes where?** - tasks, handlers, templates, files, defaults (tunables), vars
    (constants per OS), meta (deps, galaxy_info, `argument_specs.yml`). [L06]
32. **(M) What are role argument specs for?** - validated before the role runs; types/required/choices; a
    breaking change surfaces as a clear error. [L06, R03]
33. **(M) How do you pin roles and collections?** - `requirements.yml` with exact versions / git tags, never
    branches; install fresh in CI; bump deliberately. [L07, R03]
34. **(M) Which copy of a collection does Ansible use?** - the first match in the search path, playbook-adjacent
    `collections/` first; `ansible-galaxy collection list`; don't vendor `ansible_collections/` trees. [R04]
35. **(M) Role dependencies run twice - when?** - different parameters (or `allow_duplicates`); one owner per
    setting. [R05]

## Secrets

36. **(J) Vault basics?** - AES256 files or inline strings; password sources: file, script, client script
    (`--vault-id label@...-client`); `vault_identity_list`. [L08, S01]
37. **(M) What does 2.22's secret masking cover - and what not?** - vault values, `no_log` options, password
    lookups, `register_secret` -> `$REDACTED$`; plain data (JSON files, API responses) is not masked; masking
    is substring-based. [L08, T05, S02, S04]
38. **(M) A secret appears in CI logs - where can it come from?** - loop item labels, `-v` results, `--diff`,
    debug; fixes: `no_log`, `loop_control.label`, `diff: false`, `register_secret` - then rotate. [S02, S04]
39. **(S) The vault password was committed. Remediation?** - new password from a secret store, `rekey` all vault
    files, re-encrypt inline strings, remove + ignore the file, rotate the secrets themselves; history rewrite is
    hygiene, not remediation. [S03]

## Testing, CI & execution environments

40. **(J) What does ansible-lint check, and what are profiles?** - syntax, FQCN, naming, YAML, risky patterns;
    profiles min -> production; fix rather than `skip_list`/`noqa`. [L11, X01]
41. **(M) What does molecule add over lint?** - converge on a real target, idempotence, verify; here with the
    delegated driver against a lab node. Timestamps in templates break idempotence. [L11, X02]
42. **(M) What is an execution environment?** - a container image with ansible-core, collections, Python and
    system deps; built with ansible-builder (v3 definition), run by navigator/AAP. [L12]
43. **(S) The EE definition was fixed but CI still fails. Why?** - nobody built/tagged a new image; tags must be
    immutable and pinned; build EEs in CI on change. [X03]
44. **(S) Platform differences you design roles for?** - package/service names (apache2/httpd, ssh/sshd,
    cron/crond), package managers, repo configuration in air-gapped networks, paths; generic modules + per-OS
    vars via `first_found`. [P01-P03, L06]

## Wave 2: events, cloud inventory, execution control, module testing

45. **(M) What is Event-Driven Ansible?** - ansible-rulebook: sources (webhook, Kafka, Alertmanager...) feed events
    to rules (`condition` + `action`) evaluated by a Drools engine; actions run playbooks/modules or, in AAP, job
    templates. Runs as an *activation* in a decision environment. `event.payload` holds the webhook body. [L15]
46. **(M) An alert arrives (HTTP 200) but no remediation runs - how do you debug it?** - check whether a rule fired
    (activation log, `--print-events`, a catch-all `print_event` rule); compare the condition with the real payload
    (format changes); then check the playbook's host pattern - "no hosts matched" is only a warning. [D01]
47. **(S) How do you stop automatic remediation from making an incident worse?** - `throttle` (`once_within` +
    `group_by_attributes` per host), scope to the affected host, idempotent/state-checking playbooks, escalate
    repeated firing to a human, a kill switch. [D02]
48. **(M) Dynamic inventory from AWS: what do you configure?** - `*.aws_ec2.yml` file name, `regions`, server-side
    `filters` (env tag, `instance-state-name: running`), `hostnames` vs `compose: ansible_host`, `keyed_groups`,
    credentials from the environment/role; caching only with short timeouts or `--flush-cache` in jobs. [L16, I07, I08]
49. **(S) When is `strategy: free` unsafe?** - when a task depends on other hosts' runtime state (`hostvars` facts,
    `run_once`, delegated coordination); a play boundary is the barrier; `serial`/`throttle` are not barriers. [E07]
50. **(M) `delegate_to` in a play of 30 hosts - how often and how concurrently does the task run?** - once per host,
    up to `forks` at a time; shared state needs `throttle: 1`, `run_once` + loop, or a lock. [E08]
51. **(S) `serial: [1, 2]` with `max_fail_percentage: 50` - when does the rollout stop?** - per batch, only when the
    failed share is *greater than* 50 %: 1 of 2 continues. `order` re-sorts hosts before batching - a canary
    should be explicit. [E09]
52. **(M) What does `ansible-test sanity` check for a module?** - docs vs `argument_spec` (validate-modules), import
    on a bare target, pylint, pep8, yamllint, shebang, compile...; fix code/docs instead of ignore files. [X05]
