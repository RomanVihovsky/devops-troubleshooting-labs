## Hint 1
Run `ci/deploy.sh` and read the **first** warning lines, before the inventory warnings. Which config file is
used? (`ansible-config dump --only-changed` from inside the build directory.)

## Hint 2
Ansible refuses to load `ansible.cfg` from a world-writable current directory - anyone could have dropped it
there (e.g. a config with a malicious callback plugin). Without it: no inventory path, no remote user.

## Hint 3
Don't make the build directory world-writable (`chmod 0755`, or create it with the runner's own user/umask).
`ANSIBLE_CONFIG=/path/to/ansible.cfg` would also work - but fix the permissions, they are the actual risk.
