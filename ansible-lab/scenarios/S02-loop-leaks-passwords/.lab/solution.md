# Solution - masking covers known secrets only: no_log for loops over secrets

**Root cause**: the passwords come from a JSON file - plain data to Ansible. 2.22's masking knows vault values,
`no_log` options, `register_secret` and password lookups; the module's `password` option gets the hash, so the
plain text lives only in the loop item - printed in every `(item=...)` line and in `-v` results.

**Fix**: `no_log: true` on the task (+ a `loop_control.label` so the log still says which user). Then: the
passwords were in 90-day CI logs - HR must re-issue them, and the old log artifacts must be purged.

**Interview notes**
* `no_log` hides the task's result entirely - including failure messages; debug with care (temporarily, locally).
* `loop_control.label` only changes the summary line; `-v` still prints each item's full result.
* Alternative at the source: mark values as secret when loading them (`| ansible.builtin.register_secret`).
* `DEFAULT_NO_LOG` exists but hides everything - not a fix.
