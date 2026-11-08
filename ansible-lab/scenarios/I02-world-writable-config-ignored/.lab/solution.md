# Solution - world-writable directory, ansible.cfg ignored

**Root cause**: `chmod -R 0777` on the build directory. Ansible prints
`Ansible is being run in a world writable directory (...), ignoring it as an ansible.cfg source` and continues
with defaults: no inventory path (implicit localhost only), no `remote_user`.

**Fix**: no world-writable build dirs (`chmod -R go-w`, run the job as the checkout user, or a proper umask).

**Interview notes**
* The rule exists because `ansible.cfg` can load plugins (callbacks, connection, lookups) from paths it names -
  a writable directory is a code-execution vector.
* `ANSIBLE_CONFIG` is the explicit, auditable alternative; `ansible --version` prints the config file in use.
* Read warnings top-down: the first one is usually the cause, the rest are consequences.
