## Hint 1
Two plays in one file: play 1 `hosts: db` records the migration (`ansible.builtin.lineinfile` with
`line: "migrate to {{ app_release }}"` is idempotent by nature); play 2 `hosts: app`, `serial: 1`.

## Hint 2
```yaml
pre_tasks:
  - community.general.haproxy: {state: disabled, backend: app, host: "{{ inventory_hostname }}",
      socket: /run/haproxy/admin.sock}
    delegate_to: lb1
```
and the mirror image in `post_tasks` with `state: enabled`, `wait: true`.

## Hint 3
Inside `tasks`: release marker + config template (notify `Restart nginx`), then
`ansible.builtin.meta: flush_handlers`, then `ansible.builtin.uri: url=http://{{ inventory_hostname }}:8080/health`
with `register`, `until: result.status == 200`, `retries: 10`, `delay: 1`, `delegate_to: lb1`.
