## Hint 1
Look at the log: where does the password appear? (`(item=...)` lines, and the `-v` result of each item.)

## Hint 2
2.22 masks values it *knows* are secrets: vault, `no_log` module options, `register_secret`, password lookups.
A value read from a JSON file is just data. The module's `password` option receives the **hash** - the
plain text only lives in the loop item.

## Hint 3
`no_log: true` on the task (hides the whole result, items included). `loop_control: {label: "{{ item.name }}"}`
alone is not enough: with `-v` the full item is still in each result. Afterwards: ask HR to re-issue the
passwords - they were in the logs.
