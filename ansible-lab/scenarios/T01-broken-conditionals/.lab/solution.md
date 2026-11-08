# Solution - conditionals must be booleans (ansible-core >= 2.19)

**Root cause**: 2.19's templating overhaul made non-boolean conditionals an error. The repo relied on
truthiness: `when: enable_tls` with the string `"yes"`, `assert: that: app_name` (str) / `app_port` (int),
`failed_when: nginx_test.rc` (int).

**Fix**
```yaml
# group_vars/all.yml - real booleans
enable_tls: true
# role
that: [app_name | length > 0, app_port | int > 0]
failed_when: nginx_test.rc != 0
when: enable_tls | bool          # also safe for "yes"/"no" strings from -e or env
```

**Interview notes**
* Under the old rules `enable_tls: "no"` was **truthy** - the error exposes real latent bugs.
* 2.22's error names the **origin** of the bad value (`group_vars/all.yml:1:11`) - data tagging (2.19+)
  tracks where every value came from. Read the location, not just the task.
* `ALLOW_BROKEN_CONDITIONALS` downgrades the error to a warning: a diagnostic, not a fix (and it goes away).
* Also new since 2.19: embedded `{{ }}` in `when`/`that` is an error (T02), native types only (T06), untrusted
  templates don't render (T07). Read the 2.19 porting guide before any upgrade from <= 2.18.
* Upgrade safely: run the new core in CI on a branch (`--check`, ansible-lint), not in production first.
