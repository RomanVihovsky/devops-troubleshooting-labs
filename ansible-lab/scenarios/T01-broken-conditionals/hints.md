## Hint 1
Run it and read every error: which tasks, which expressions, and what type each expression returns
(`str`, `int`). Since 2.19 a condition must evaluate to a real boolean - Ansible no longer guesses.

## Hint 2
Two families of fixes: make the **data** boolean (`enable_tls: true` instead of `"yes"`), or make the
**expression** boolean (`enable_tls | bool`, `app_name | length > 0`, `result.rc != 0`).
Careful: under the old rules the *string* `"no"` was truthy too.

## Hint 3
`group_vars/all.yml`: real booleans. Role: `that: [app_name | length > 0, app_port | int > 0]`,
`failed_when: nginx_test.rc != 0`. Then `ansible-playbook site.yml --check` -> no errors, no changes.
