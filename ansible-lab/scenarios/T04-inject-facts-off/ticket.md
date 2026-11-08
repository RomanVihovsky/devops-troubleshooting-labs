# CI preview of the 2.24 defaults: "'ansible_os_family' is undefined"
**PLAT-40** · P3 · Reporter: platform team

ansible-core 2.24 stops injecting facts as top-level variables (`ansible_distribution`, `ansible_hostname`...).
CI now runs with `ANSIBLE_INJECT_FACT_VARS=False` (so does your lab shell) and `site.yml` fails.
On the current default the run floods the log with `INJECT_FACTS_AS_VARS` deprecation warnings.

`/etc/acme/node.json` is read by the CMDB - every field must stay correct on both OS families.

**Test**: site.yml converges with injection off; node.json is correct on web1 (Debian 12) and web2 (Rocky 9),
including the Python version; no `INJECT_FACTS_AS_VARS` deprecation with the old default.
