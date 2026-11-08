# Web-only deploys fail: "object of type 'dict' has no attribute 'all_ipv4_addresses'"
**OPS-247** · P2 · Reporter: CI

To save time, the web pipeline now runs `ansible-playbook site.yml --limit web`. It fails when rendering
`/etc/acme/db.conf` - the full run (no `--limit`) works fine.

The web pipeline must keep `--limit web` and must not touch the database host's configuration.

**Test**: `site.yml --limit web` converges on a fresh runner (no fact cache); web1's `db.conf` points at db1's address;
nothing is changed on db1.
