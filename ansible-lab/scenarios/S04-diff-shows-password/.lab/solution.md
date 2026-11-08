# Solution - diff: false for templates that hold secrets

**Root cause**: `--diff` shows before/after of every template. The password comes from a JSON export - plain data
to Ansible, so 2.22 doesn't mask it (vaulted values would be masked). The PR bot posted both versions.

**Fix**: `diff: false` on the task (it still reports `changed`), and/or `| ansible.builtin.register_secret` where
the value is loaded so it is masked everywhere. Then rotate the password again - it is in the PR history.

**Interview notes**
* `diff: false` (task keyword) beats `--diff`; `no_log: true` would hide the change itself.
* `ANSIBLE_DIFF_ALWAYS` / `[diff] always = True` in CI makes this class of leak more likely.
* Lookups of secret stores (`hashi_vault`, `aws_ssm`, password lookups) are known secrets; a `file` lookup is not.
