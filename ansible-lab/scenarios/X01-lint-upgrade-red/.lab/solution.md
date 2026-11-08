# Solution - fix the findings, don't hide them

**Root cause**: a 2021 playbook meets a 2026 linter: short module names, `yes`, `key=value` arguments, files without
`mode`, an unnamed play, lowercase names, `{{port}}`, a variable named `port` (a reserved play keyword), `== True`, and a `command` that reloads nginx on every run.

**Fix**: FQCNs, YAML booleans, YAML arguments, explicit modes, names, Jinja spacing, a plain boolean `when`, and a
**handler** instead of the unconditional reload (which also removes a needless reload per run).

**Interview notes**
* Profiles: `min` < `basic` < `moderate` < `safety` < `shared` < `production` - each adds rules.
* `skip_list` disables a rule everywhere; `# noqa rule` one line; `.ansible-lint-ignore` per-file baselines -
  OK for a migration plan with an owner and a date, not as the fix.
* `ansible-lint --fix` (transformers) handles FQCN, truthy, spacing, key order automatically - review the diff.
* `risky-file-permissions`: without `mode`, the result depends on umask and on the module version.
