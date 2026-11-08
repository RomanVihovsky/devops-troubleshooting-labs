# Security scan: prod web1 has no hardening marker - every deploy is green
**SEC-77** · P2 · Reporter: security scanner

Since the platform team switched CI to the **ansible-core 2.23 preview defaults** (`ci/pipeline.sh`; your lab
shell runs with them too: `ANSIBLE_ALLOW_EMBEDDED_TEMPLATES=False`), the baseline deploy is green and reports
nothing to do - but the scanner says prod `web1` is missing `/etc/acme/prod-hardening`.
Nothing failed, nothing printed a warning.

The 2.23 preview stays on.

**Test**: with the preview on, prod hosts get the hardening marker and staging hosts don't; only enabled sysctl
settings are written; no templating-delimiter warnings or deprecations (with the preview off either); site.yml converges.
