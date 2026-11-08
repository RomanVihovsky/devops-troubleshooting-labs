## Hint 1
Enable the `ansible.posix.profile_tasks` and `ansible.posix.timer` callbacks
(`ANSIBLE_CALLBACKS_ENABLED=ansible.posix.profile_tasks,ansible.posix.timer ansible-playbook site.yml`). Which tasks
eat the time? Does the run use more than one host at a time? (`ansible-config dump --only-changed`)

## Hint 2
Three multipliers: `forks = 1` (hosts one after another), one package-manager call **per item** (7 calls per host
instead of 1), and fact gathering in every one of the four plays.

## Hint 3
`forks` back to a sane number (10+); `name: [jq, rsync, ...]` as one list; gather facts once - `gather_facts: false`
in the later plays (facts persist for the run) or `gathering = smart` + a fact cache.
