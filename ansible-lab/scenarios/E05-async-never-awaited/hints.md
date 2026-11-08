## Hint 1
`async: 600` + `poll: 0` = "start it and move on" (fire and forget). What does the next task fetch?

## Hint 2
Ansible returns a job id (`ansible_job_id`) for async tasks. `ansible.builtin.async_status` checks a job;
combine it with `until` to wait without holding one long SSH session.

## Hint 3
`register: dump_job` on the dump task, then
`ansible.builtin.async_status: {jid: "{{ dump_job.ansible_job_id }}"}`, `register: dump_result`,
`until: dump_result.finished`, `retries: 120`, `delay: 3` - before the fetch. (Or `poll: 3` on the dump task.)
