## Hint 1
Facts always live in `ansible_facts` - the `ansible_*` top-level copies are the legacy injection.
`ansible -m setup web1 -a 'filter=distribution*'` shows the keys (without the `ansible_` prefix).

## Hint 2
Not every `ansible_*` name is a fact: `ansible_check_mode`, `ansible_host`, `ansible_user` are magic or
connection variables - leave them. And watch out for a fact behind `default(...)`: it does not fail, it
silently returns the default.

## Hint 3
`ansible_facts['os_family']`, `ansible_facts['hostname']`, `ansible_facts['distribution']`,
`ansible_facts['distribution_major_version']`, `ansible_facts['processor_vcpus']`, `ansible_facts['python_version']`.
`grep -rn 'ansible_[a-z]' roles/` finds them.
