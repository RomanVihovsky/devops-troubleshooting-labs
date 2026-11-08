## Hint 1
How many hosts does Ansible touch at once in `deploy.yml`, and what makes it stop? Look up the play
keywords `serial` and `max_fail_percentage`.

## Hint 2
One node at a time is not enough if the load balancer still sends traffic to the node you are restarting.
Take it out first and put it back only when it is healthy: `community.general.haproxy` with
`delegate_to: lb1` (the admin socket is `/run/haproxy/admin.sock`), `ansible.builtin.uri` with `until:`.

## Hint 3
`serial: 1` + `max_fail_percentage: 0`; `pre_tasks`: disable the node in backend `web`; tasks; then
`ansible.builtin.meta: flush_handlers` so the restart happens *now*; wait for `/health` = 200; `post_tasks`:
enable it again. A failed node stays drained - exactly what you want.
