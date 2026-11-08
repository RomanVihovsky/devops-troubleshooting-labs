# L04 · Templates, handlers and validate
**Learn** · Jinja2 loops over inventory, hostvars, notify/handlers, validate, flush_handlers · ~25 min

`site.yml` already runs nginx on web1 + web2 (8080, page names the host). Put **haproxy on lb1** in front:

1. Write `templates/haproxy.cfg.j2`: frontend on port 80, backend `web` with one `server` line **per host of
   group `web`** (a Jinja `for` loop over `groups['web']`), health check `GET /health`, `balance` from `haproxy_balance`.
   `haproxy_maxconn` (group_vars) goes into `global`.
2. In the lb play: install haproxy, template to `/etc/haproxy/haproxy.cfg` with
   **`validate: haproxy -c -f %s`**, notify a handler that **reloads** haproxy, keep haproxy started.
3. Prove `validate` protects you: `ansible-playbook site.yml -e haproxy_balance=fastest` must fail at the
   template task and leave the live config and service untouched.
4. `curl http://lb1/` a few times from the controller: answers alternate between web1 and web2.

**Test**: lb1 balances across web1 and web2; the config lists every web host; an invalid value is
rejected by `validate` without touching the running config; site.yml converges.
