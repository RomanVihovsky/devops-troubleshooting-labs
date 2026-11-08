# L02 · First playbook on two OS families
**Learn** · plays, modules, templates, idempotence, check/diff · ~20 min

Write `site.yml` so that both web nodes (web1 = Debian 12, web2 = Rocky 9) serve a page on port **8080**.

1. Install `nginx` with `ansible.builtin.package` (works with apt and dnf).
2. Template `templates/site.conf.j2` to `/etc/nginx/conf.d/site.conf` (a `server` on 8080, root
   `/usr/share/nginx/html` - the same path on both distros).
3. Template `templates/index.html.j2` to `/usr/share/nginx/html/index.html`:
   `Hello from <hostname> running <distribution> <major version>` - use `ansible_facts[...]`.
4. Start and enable nginx (`ansible.builtin.service`), reload it when the config changes (a handler).
5. Run it; run it again (`changed=0`); try `--check --diff` after editing the page template.

**Test**: both nodes answer on 8080 with their own hostname and distribution; nginx is enabled; a second
run (check mode) changes nothing.
