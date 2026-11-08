# Solution - L13

| Legacy (2.16) | 2.22 | Why |
|---|---|---|
| `that: "{{ app_port }} > 1024"` | `that: app_port > 1024` | 2.19: no template delimiters inside expressions |
| `loop: "{{ range(1, 4) }}"` | `"{{ range(1, 4) \| list }}"` | 2.19: `range` objects can't be stored |
| `create_dirs: "yes"` / `when: create_dirs` | `true` / `create_dirs \| bool` | 2.19: conditionals must be booleans |
| `mode: "{{ omit }}"` in a loop item | omit the key, `item.mode \| default(omit)` | 2.19: `omit` no longer leaks through items |
| `ansible_distribution` | `ansible_facts['distribution']` | 2.20: deprecated, off by default in 2.24 |
| `play_hosts` | `ansible_play_hosts` / `ansible_play_batch` | removed in 2.23 |
| `follow_redirects: yes` | `safe` / `all` / `none` | 2.22: yes/no removed |

**Takeaways**
* Upgrade one minor version at a time in CI, read every porting guide in between, and run with
  `ANSIBLE_INJECT_FACT_VARS=False` today to be ready for 2.24.
* Treat deprecation warnings as failures in CI (grep for them, or `deprecation_warnings` + log parsing) - they
  are next year's outage.
* `ansible-lint` flags many of these (`jinja[invalid]`, deprecated features) before they hit production.
