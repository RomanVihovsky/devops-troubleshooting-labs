## Hint 1
Run the role twice and diff (`ansible-playbook` with `--diff` on the second run, or `molecule converge` twice +
`molecule idempotence`). What line changes?

## Hint 2
A template that embeds the current time is different on every run - Ansible correctly reports `changed`.
"When was it deployed" belongs in logs or in the file's mtime, not in its content.

## Hint 3
Drop the timestamp (`# Managed by Ansible - do not edit` is enough). Don't silence the task with
`changed_when: false` - the verify checks that a real change (another kernel/OS value) is still reported.
