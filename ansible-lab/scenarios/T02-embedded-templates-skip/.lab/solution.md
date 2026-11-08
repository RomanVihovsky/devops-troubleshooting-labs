# Solution - embedded templates in conditionals

**Root cause**: `when: "'{{ inventory_hostname }}' in groups['prod']"` puts a template *inside a string constant
of an expression*. Up to 2.22 Ansible still renders it (with a warning); with the 2.23 default
`ALLOW_EMBEDDED_TEMPLATES=False` it is a plain string - `'{{ inventory_hostname }}'` is never a member of
`groups['prod']`, so the task is **silently skipped**. No error, no warning.

**Diagnose**: `-v` shows `skipping: [web1]`; toggling `ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=True` brings back the
warning *"Jinja constant strings should not contain embedded templates"* with the exact file:line:column.

**Fix**: bare expressions - `when: inventory_hostname in groups['prod']`, `when: item.enabled`.

**Interview notes**
* `when`, `until`, `changed_when`, `failed_when`, `assert.that` are expressions - never `{{ }}` inside them.
* 2.19 introduced the templating overhaul; 2.22 still tolerates embedded templates (warning), 2.23 stops.
* Pre-flight a future default in CI (`ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=False`, `ANSIBLE_INJECT_FACT_VARS=False`)
  and treat new deprecations as failures: silent behaviour changes are worse than errors.
* `ansible-lint` flags `no-jinja-when` for the `{{ }}`-wrapped form.
