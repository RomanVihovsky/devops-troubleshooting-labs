## Hint 1
Run it, fix the first error, run again. `ANSIBLE_INJECT_FACT_VARS=False ansible-playbook site.yml` shows
what 2.24 will do. Every message names the task and often the exact file position.

## Hint 2
`that: app_port > 1024` · `loop: "{{ range(1, 4) | list }}"` · `create_dirs: true` (+ `| bool` in `when` if
it may come from `-e`) · items without a `mode` key + `mode: "{{ item.mode | default(omit) }}"`.

## Hint 3
`ansible_facts['distribution']`, `ansible_facts['distribution_major_version']`, `ansible_play_hosts` (or
`ansible_play_batch`) instead of `play_hosts`, `follow_redirects: safe`.
